#!/usr/bin/perl

use XML::LibXML;
use URI::URL;
use JSON;

$debug = 1;
sub DEBUG { return unless $debug; my $m = shift @_; print STDERR "$m\n"; }

my $arrProd = [];
my $arrCats = [];
my $arrSubCats = [];
my $apiurl = undef;
$apiurl = $ARGV[2] if $ARGV[1] == 'api';

#
# get pages
#
my $arrPages = [{
   'url' => "$ARGV[0]/shop/department.asp?storeID=D92VLAQVMPDL9L5UHTS2WLU67NADEHUA"
  ,'localfile' => 'department.html'
  ,'type' => 'department'
}];
for (my $p=0; $p < scalar @$arrPages; $p++ )
{
  my $url;
  my $localfile;
  my $debugout = '';
  my $hrPage = $arrPages->[$p];

  # count
  $debugout .= "(". $p ."/". @$arrPages .")";

  # type
  if ( $hrPage->{'type'} )
  {
    $type = $hrPage->{'type'};
    $debugout .= " [". $type ."]";
  }

  # localfile
  if ( $hrPage->{'localfile'} )
  {
    $localfile = $hrPage->{'localfile'};
    $debugout .= " <". $localfile .">";
  }

  # url
  if ( $hrPage->{'url'} )
  {
    $url = $hrPage->{'url'};
    $debugout .= " ". $url;
  }

  # unless local file exists
  unless ( -r $localfile )
  {
    $debugout .= " *downloading*";
    my $result = `curl --silent "$url" -o $localfile`;
    $debugout .= " {". $result ."}" if length($result) > 0;
  }

  # unless image
  unless ( $type eq 'image' )
  {
    $debugout .= " *loading*";
    my $html = do {
      local $/ = undef;
      open my $fh, "<", $localfile
        or die "could not open $localfile: $!";
      <$fh>;
    };
    $arrCats = parseCategorylist($html, $arrPages) if $type eq 'department';
    parseSubCategorylist($html, $arrPages) if $type eq 'subcategory';
    parseItemlist($html, $arrPages, $arrProd, $p) if $type eq 'subcategory2';
  }

  # debug
  DEBUG $debugout;
  $debugout = '';
}

exportTSV() if $ARGV[1] == 'tsv';
#exportAPI($ARGV[2]) if $ARGV[1] == 'api';
exit;


#
# export in TSV format
#
sub exportTSV {
  my @arrKeys = (
     'id'
    ,'category_id'
    ,'category'
    ,'subcategory_id'
    ,'subcategory'
    ,'brand'
    ,'product'
    ,'size'
    ,'upc'
    ,'price'
    ,'url'
    ,'imgurl');

  # tsv head
  foreach my $key (@arrKeys) { print $key ."\t"; }
  print "\n";

  # tsv data
  foreach my $arr (@$arrProd)
  {
    foreach my $key (@arrKeys) { print $arr->{$key} ."\t"; }
    print "\n";
  }
}

#
# export to API
#
sub exportAPI {

  my @arrKeys = (
     'id'
    ,'category_id'
    ,'category'
    ,'subcategory_id'
    ,'subcategory'
    ,'brand'
    ,'product'
    ,'size'
    ,'upc'
    ,'price'
    ,'url'
    ,'imgurl');

  # tsv data
  foreach my $arr (@$arrProd)
  {
    foreach my $key (@arrKeys) { print $arr->{$key} ."\t"; }
    print "\n";
  }

}

#
# parse categories
#
sub parseCategorylist {
  my $html = shift(@_);
  my $arrPages = shift(@_);
  my $p = scalar @$arrPages;
  my $arrCats = [];
  @html = split("\n", $html);
  my $i = 0;
  DEBUG "parseCategories()...";
  foreach $_ (@html)
  {
    if ( $_ =~ /href='([^']+)'>([^<]+)\</ )
    {
      my $hr = {
         'url'  => $1
        ,'category' => $2
      };
      $hr->{'url'} =~ s/\&amp;/\&/g;
      foreach my $key ( qw/ storeID category_id / )
      {
        $hr->{$key} = $1 if $hr->{'url'} =~ /$key=([^\&]+)/;
      }
      my $id;
      $id = $hr->{'id'} if $hr->{'id'};
      $id = $hr->{'category_id'} unless $hr->{'id'};
      $hr->{'type'} = $1 if $hr->{'url'} =~ /\/shop\/(subcategory|subcategory2|product_view)\.asp/;
      if ( $hr->{'type'} )
      {
        #DEBUG "adding $hr->{'type'} to pages: ". $hr->{'url'};
        $arrPages->[$p++] = {
          'url' => $ARGV[0]. $hr->{'url'}
          ,'type' => $hr->{'type'}
          ,'localfile' => $hr->{'type'} ."_". $id .".html"
        };
        DEBUG "parsed $i ; type = ". $hr->{'type'} ." ; url = ". $hr->{'url'};
        $arrCats->[$i++] = $hr;

        # push into api
        if ($apiurl)
        {
          my $jsonhr = {
            'id' => $hr->{'category_id'}
            ,'name' => $hr->{'category'}
          };
          my $json_text = encode_json $jsonhr;
          my $command = 'curl --silent --header "Content-Type:application/json" -XPOST "'. $apiurl .'/Category/create" -d '. "'". $json_text ."'";
          DEBUG "posting to API: ". $command;
          my $result = `$command`;
          print $result if length $result;
        }

      } #hr->{type}

    } # if ( $_ =~ /href='([^']+)'>([^<]+)\</ )

  } # foreach

 return $arrCats;
}


#
# parse subcategory
#
sub parseSubCategorylist {
  my $html = shift(@_);
  my $arrPages = shift(@_);
  my $p = scalar @$arrPages;
  my $arSubCats = [];
  @html = split("\n", $html);
  my $i = 0;
  my $bump = "     ";
  DEBUG "-> parseSubCategories()";

  my $dom = XML::LibXML->load_html(string => $html, recover => 2);
  DEBUG "<<< XML::LibXML->load_html() complete";

  my $results = $dom->findnodes('//div[@class="clsListResult"]/a');
  foreach my $context ($results->get_nodelist)
  {
    if ( $context =~ /href="([^"]+)">(.+)<\/a>/ )
    {
      my $hr = {};
      $hr->{'url'} = $ARGV[0] . $1;
      $hr->{'url'} =~ s/\&amp;/\&/g;

      # process url keys and values
      my $url = url $hr->{'url'};
      DEBUG $bump."url: ". $hr->{'url'};
      DEBUG $bump."path: ". $url->path;
      DEBUG $bump."query: ". $url->equery;
      my @arr = $url->query_form;
      while ( $#arr > -1 )
      {
        my $key = shift @arr;
        $hr->{$key} = shift @arr;
        DEBUG $bump."$key: $hr->{$key}";
      }

      # add to pages
      my $id = undef;
      $id = $hr->{'id'} if $hr->{'id'};
      $id = $hr->{'category_id'} if $hr->{'category_id'};
      $id = $hr->{'subcategory_id'} if $hr->{'subcategory_id'};
      $hr->{'type'} = $1 if $hr->{'url'} =~ /\/shop\/(subcategory|subcategory2|product_view)\.asp/;
      if ( $hr->{'type'} )
      {
        DEBUG "+++ [$hr->{'type'}] ". $hr->{'url'};
        $arrPages->[$p++] = {
          'url' => $hr->{'url'}
          ,'type' => $hr->{'type'}
          ,'localfile' => $hr->{'type'} ."_". $id .".html"
          ,'category_id' => $hr->{'category_id'}
          ,'category' => $hr->{'category'}
          ,'subcategory_id' => $hr->{'subcategory_id'}
          ,'subcategory' => $hr->{'subcategory'}
        };
      }
      $arSubCats->[$i++] = $hr;

      # push into api
      if ($apiurl)
      {
        my $jsonhr = {
          'id' => $hr->{'subcategory_id'}
          ,'parent' => $hr->{'category_id'}
          ,'name' => $hr->{'subcategory'}
        };
        my $json_text = encode_json $jsonhr;
        my $command = 'curl --silent --header "Content-Type:application/json" -XPOST "'. $apiurl .'/Category/create" -d '. "'". $json_text ."'";
        DEBUG "posting to API: ". $command;
        my $result = `$command`;
        print $result if length $result;
      }

    } # if ( $context =~ /href="([^"]+)">(.+)<\/a>/ )

  }

  return $arSubCats;
}

#
# parse subcategory2
#
sub parseItemlist {
  my $html = shift(@_);
  my $arrPages = shift(@_);
  my $p = scalar @$arrPages;
  my $arrProd = shift(@_);
  my $n = scalar @$arrProd;
  my $c = shift(@_);
  my $hrPage = $arrPages->[$c];
  @html = split("\n", $html);
  my $i = 0;
  my $bump = "     ";
  my $hr = {};
  DEBUG "-> parseSubCategory2()";

  my $dom = XML::LibXML->load_html( string => $html, recover => 2 );

  DEBUG "<<< XML::LibXML->load_html() complete";

  my $results = $dom->findnodes('//div[@id="midCol"]/table[1]/tr[3]/td[2]/table/tr/td[@valign="top" or @valign="bottom"]');
  foreach my $context ($results->get_nodelist)
  {

    DEBUG "--- ". $context;
    if ( $context =~ /<img src="([^"]+)".+alt="([\d]+)"\/>/ )
    {
      DEBUG $bump."imgurl: $1";
      DEBUG $bump."upc: $2";
      $hr->{'imgurl'} = $1;
      $hr->{'upc'} = $2;

      # post process imgurl
      $hr->{'imgurl'} = $ARGV[0] . $hr->{'imgurl'} unless $hr->{'imgurl'} =~ /^http/;

      # add to pages for download
      DEBUG "+++ [image] ". $hr->{'imgurl'};
      $arrPages->[$p++] = {
         'url' => $hr->{'imgurl'}
        ,'type' => 'image'
        ,'localfile' => substr($hr->{'imgurl'}, rindex($hr->{'imgurl'}, '/') + 1)
      } if index $hr->{'imgurl'}, $ARGV[0] > -1;
    }

    # --- <td valign="top"><a class="ProductBrowse" href="/shop/product_view.asp?id=156377&amp;StoreID=D92VLAQVMPDL9L5UHTS2WLU67NADEHUA&amp;private_product=0">
    # <b>WiseWays Herbals</b></a><br/>
    # <a class="ProductBrowse" href="/shop/product_view.asp?id=156377&amp;StoreID=D92VLAQVMPDL9L5UHTS2WLU67NADEHUA&amp;private_product=0">
    # Bamboo Scents - 17 Reeds, 1 oz. Aromatic Oil
    # </a></td>
    elsif ( $context =~ /<a class="ProductBrowse" href="([^"]+)"><b>([^<]+)<\/b><\/a><br\/><a class="ProductBrowse" href="([^"]+)">([^<]+)<\/a>/ )
    {
      DEBUG $bump."url: $1";
      DEBUG $bump."brand: $2";
      DEBUG $bump."product: $4";
      $hr->{'url'} = $ARGV[0] . $1;
      $hr->{'brand'} = $2;
      $hr->{'product'} = $4;
      $hr->{'url'} =~ s/\&amp;/\&/g;

      # process url query keys and values
      my $url = url $hr->{'url'};
      DEBUG $bump."url: ". $hr->{'url'};
      my @arr = $url->query_form;
      while ( $#arr > -1 )
      {
        my $key = shift @arr;
        $hr->{$key} = shift @arr;
        DEBUG $bump."$key: $hr->{$key}";
      }
      foreach my $key ( ('category_id','subcategory_id','category','subcategory') )
      {
        DEBUG $bump."$key: $hrPage->{$key}";
        $hr->{$key} = $hrPage->{$key};
      }
    }

    # --- <td valign="top"><br/><a class="ProductBrowse" href="/shop/product_view.asp?id=156377&amp;StoreID=D92VLAQVMPDL9L5UHTS2WLU67NADEHUA&amp;private_product=0"/></td>
    elsif ( $context =~ /<br\/><a class="ProductBrowse" href="([^"]+)">([^<]+)<\/a>/ )
    {
      DEBUG $bump."url: $1";
      DEBUG $bump."size: $2";
      $hr->{'size'} = $2;
    }

    # --- <td valign="top" align="right"><br/>$8.00</td>
    elsif ( $context =~ /(\$[\d]+\.[\d]{2})/ )
    {
      $hr->{'price'} = $1;

      # debug
      foreach my $key ( keys %$hr )
      {
        DEBUG $bump."$key: $hr->{$key}";
      }

      # save hashref
      $arrProd->[$n] = $hr;

      # push into api
      if ($apiurl)
      {
        my $jsonhr = {
          'id' => $hr->{'id'}
          ,'categories' => [ int($hr->{'category_id'}) ]
          ,'name' => $hr->{'product'}
          ,'description' => $hr->{'size'}
          ,'price' => $hr->{'price'}
        };
        $jsonhr->{'upc'} = $hr->{'upc'} if length($hr->{'upc'}) == 12;
        $jsonhr->{'price'} =~ s/^\$//; # remove dollar sign
        my $json_text = encode_json $jsonhr;
        my $command = 'curl --silent --header "Content-Type:application/json" -XPOST "'. $apiurl .'/Product/create" -d '. "'". $json_text ."'";
        DEBUG "posting to API: ". $command;
        my $result = `$command`;
        print $result if length $result;
      }

      # close out hashref
      $hr = {};

      # next position
      DEBUG "+++ arrProd: ". $n;
      $n++;
    }
  }

  return $arrProd;
}
