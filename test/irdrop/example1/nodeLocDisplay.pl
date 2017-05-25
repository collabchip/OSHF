#!/usr/bin/perl
use Tk;
use Tk::WorldCanvas;
use Math::Round;
use Tk::Font;

my $numOfArg = @ARGV;
if($numOfArg < 4 || $ARGV[0] eq "-h" || $ARGV[0] eq "-H" || $ARGV[0] eq "-help" || $ARGV[0] eq "-HELP"){
   print "nodeLocDisplay.pl -nodeMapLocFile <file name (default is nodeLoc.txt)>\n";
   print "                  -resultFile <file name (default is IR_*.res)>\n";
}else{
   my %NODE_VS_LOC = ();
   my %NODE_VS_VOLTAGE = ();
   my ($canvasWidth, $canvasHeight) = (540, 540);
   my ($maxRow, $maxCol) = (0, 0);
   my $gridStep =  1;
   my @colorsArr = ("Red", "OrangeRed", "Orange", "Goldenrod", "yellow", "YellowGreen", "green");

   my ($nodeMapLocFile, $irResultFile) = ("nodeLoc.txt", "IR.res");
   for(my $xx=0; $xx<=$#ARGV; $xx++){
       if($ARGV[$xx] eq "-nodeMapLocFile"){ $nodeMapLocFile = $ARGV[$xx+1];}
       if($ARGV[$xx] eq "-resultFile"){$irResultFile = $ARGV[$xx+1];} 
   }
   
   ######################################## Reading nodeMap.txt file ######################################
   my %NODE_VS_LOC = ();
   my ($minX, $minY, $maxX, $maxY) = (0, 0, 0, 0);
   my $count = 0;
   open(READ_NODE_MAP_LOC_FILE, "$nodeMapLocFile");
   while(<READ_NODE_MAP_LOC_FILE>){
     chomp($_);
     my ($node, $xLoc, $yLoc) = split(/\s+/, $_);
     if(!exists $NODE_VS_LOC{$node}){
        if($count == 0){
           $minX = $maxX = $xLoc;
           $minY = $maxY = $yLoc;
        }

        if($xLoc < $minX){
           $minX = $xLoc;
        }
        if($xLoc > $maxX){
           $maxX = $xLoc;
        }
        if($yLoc < $minY){
           $minY = $yLoc;
        }
        if($yLoc > $maxY){
           $maxY = $yLoc;
        }

        $NODE_VS_LOC{$node} = $xLoc.",".$yLoc ;
        $count = 1;
     }
   }
   close(READ_NODE_MAP_LOC_FILE);
   #print "$minX, $minY, $maxX, $maxY\n";

   ######################################### Reading IR.res file ######################################
   my %NODE_VS_VOLTAGE = ();
   open(READ_IR_RES_FILE, "$irResultFile");
   while(<READ_IR_RES_FILE>){
     chomp($_);
     $_ =~ s/\s+//g;
     if($_ =~ /^\s*#/){
        next;
     }else {
        my ($node,$volt) = split(/\=/, $_);
        $node =~ s/V|\(|\)//g;
        $NODE_VS_VOLTAGE{$node} = $volt;
     }
   }
   close(READ_IR_RES_FILE);
   my @sortedVoltArray = sort {$a <=> $b} values %NODE_VS_VOLTAGE;
   #my $stepVolt = ($sortedVoltArray[-1] - $sortedVoltArray[0])/($#colorsArr+1);
   my $stepVolt = ($sortedVoltArray[-1] - $sortedVoltArray[0])/$#colorsArr;
   #print "minV:$sortedVoltArray[0] maxV:$sortedVoltArray[-1] stepV:$stepVolt\n";

   
   ######################################## GUI code ##################################################
   my $mw = MainWindow->new();
   #my $frame1= $mw->Frame()->pack(-side => 'top',-anchor=>'n', -expand=>1, -fill=>'x');
   my $frame2= $mw->Frame()->pack(-side => 'top',-anchor=>'n', -expand=>1, -fill=>'both');
   my $c = $frame2->Scrolled('WorldCanvas', -scrollbars=>'se',-bg =>'black',-width=>$canvasWidth, -height=>$canvasHeight)->pack(qw/-side left -expand 1 -fill both/);
   $c->Subwidget('xscrollbar')->configure(-takefocus => 0);
   $c->Subwidget('yscrollbar')->configure(-takefocus => 0);
   $c->configure(-confine => 1);

   $c->createRectangle(0,0,$canvasWidth,$canvasHeight, -outline,"black"); 
   my  $initial_fontsize = 8;
   my  $helveticaStd = $mw->Font(-family=> 'Arial', -size=>$initial_fontsize); 
   
   my $cktWidth = $maxX - $minX;
   my $cktHeight = $maxY - $minY;
   my $mulHFactor = ($canvasWidth - 40)/$cktWidth;
   my $mulVFactor = ($canvasHeight - 40)/$cktHeight;
   my $mulFactor = 1;
   if($mulHFactor < $mulVFactor){
      $mulFactor = $mulHFactor;
   }else{
      $mulFactor = $mulVFactor;
   }
   $c->createRectangle(20,20,20+$cktWidth*$mulFactor,20+$cktHeight*$mulFactor, -outline,"green"); 

   #my $count = 0;
   foreach my $node (keys %NODE_VS_LOC){
        my $xy = $NODE_VS_LOC{$node};
        my $voltage = $NODE_VS_VOLTAGE{$node};
        delete $NODE_VS_LOC{$node};
        delete $NODE_VS_VOLTAGE{$node};
        #print "$node $xy $voltage\n";

        my ($xLoc, $yLoc) = split(/\,/, $xy);

        my $colorIndex = round(($voltage -$sortedVoltArray[0])/$stepVolt);  
        my $color = $colorsArr[$colorIndex];

        my $xx = 20 + abs($xLoc - $minX)*$mulFactor;
        my $yy = 20 + abs($yLoc - $minY)*$mulFactor;

        my $llx = $xx - ($#colorsArr+1-$colorIndex)/2;
        my $lly = $yy - ($#colorsArr+1-$colorIndex)/2; 
        my $urx = $xx + ($#colorsArr+1-$colorIndex)/2;
        my $ury = $yy + ($#colorsArr+1-$colorIndex)/2; 

        #if($count < 100){
        #print "node:$node bbox:$llx,$lly,$urx,$ury volt:$voltage index:$colorIndex color:$color\n";
        $c->createOval($llx,$lly,$urx,$ury, -outline=>'black', -fill=>$color);
        #}
        #$count++;
   }
   close($READ_NODE_NUM_MAP_FILE);

   $c->viewAll;
   my @guiBox = $c->getView();
   #print "guiBbox: @guiBox\n";
   &canvas_zoomIn_zoomOut($mw, $c, \@guiBox, $helveticaStd, $initial_fontsize);
   $c->CanvasFocus;
   MainLoop;
}

#############################################################################################################
################################## Subroutine to ZoomIn and ZoomOut #########################################
#############################################################################################################
sub canvas_zoomIn_zoomOut{
 my @arg = @_;
 my $top = $arg[0];
 my $canvas = $arg[1];
 my @view_bbox = @{$arg[2]};
 my $topTextEle = $arg[3];
 my $initialFontsize = $arg[4];
 #print "box_orig:@view_bbox\n";

    #$canvas->CanvasFocus;
    $canvas->CanvasBind('<3>'               => sub {$canvas->configure(-bandColor => "");
                                                    $canvas->configure(-bandColor => 'red');
                                                    $canvas->rubberBand(0)});
    $canvas->CanvasBind('<B3-Motion>'       => sub {$canvas->rubberBand(1)});
    $canvas->CanvasBind('<ButtonRelease-3>' => sub {my @box = $canvas->rubberBand(2);
                                                    #print "box:@box\n";
                                                    $canvas->viewArea(@box, -border => 0);

                                                    my $xdiff = abs($view_bbox[2] - $view_bbox[0]) - abs($box[2] - $box[0]);
                                                    my $ydiff = abs($view_bbox[3] - $view_bbox[1]) - abs($box[3] - $box[1]);
                                                    my $zoomFactor = 1;
                                                    if(abs($box[2] - $box[0]) <=0 || abs($box[3] - $box[1]) <=0){return;}
                                                    if($xdiff >= $ydiff){
                                                       $zoomFact = abs(($view_bbox[2] - $view_bbox[0])/($box[2] - $box[0]));
                                                    }else{
                                                       $zoomFact = abs(($view_bbox[3] - $view_bbox[1])/($box[3] - $box[1]));
                                                    }
                                                    &text_zoomIn_zoomOut($topTextEle, $initialFontsize, $zoomFact); 
                                                    });
    $canvas->CanvasBind('<2>'               => sub {$canvas->viewArea(@view_bbox, -border => 0);&text_zoomIn_zoomOut($topTextEle, $initialFontsize, 1);});               

    $canvas->CanvasBind('<i>' => sub {$canvas->zoom(1.25);&text_zoomIn_zoomOut($topTextEle, $initialFontsize, 1.25);});
    $canvas->CanvasBind('<o>' => sub {$canvas->zoom(0.80);&text_zoomIn_zoomOut($topTextEle, $initialFontsize, 0.80);});
    $canvas->CanvasBind('<f>' => sub {$canvas->viewArea(@view_bbox, -border => 0);&text_zoomIn_zoomOut($topTextEle, $initialFontsize, 1);});
 
    $top->bind('WorldCanvas',    '<Up>' => "");
    $top->bind('WorldCanvas',  '<Down>' => "");
    $top->bind('WorldCanvas',  '<Left>' => "");
    $top->bind('WorldCanvas', '<Right>' => "");
 
    $canvas->CanvasBind('<KeyPress-Up>'   => sub {$canvas->panWorld(0,  200);});
    $canvas->CanvasBind('<KeyPress-Down>' => sub {$canvas->panWorld(0, -200);});
    $canvas->CanvasBind('<KeyPress-Left>' => sub {$canvas->panWorld(-200, 0);});
    $canvas->CanvasBind('<KeyPress-Right>'=> sub {$canvas->panWorld( 200, 0);});
}#sub canvas_zoomIn_zoomOut

#############################################################################################################
################################## Subroutine to ZoomIn/ZoomOut Text ########################################
#############################################################################################################
sub text_zoomIn_zoomOut{
  my $textElement = $_[0];
  my $initialFontsize = $_[1];
  my $zoomFactor = $_[2];

  my $maxFontSize = 20;
  #print "ifont:$initialFontsize zoom:$zoomFactor\n";

  my $currentSize = abs($textElement->actual('-size'));
  my $newSize = $currentSize * $zoomFactor; 
  if($newSize < $initialFontsize ||$zoomFactor == 1){
     $textElement->configure(-size=>$initialFontsize);
  }else{
     if($newSize >=$initialFontsize && $newSize <= $maxFontSize){
        $textElement->configure(-size=>$newSize);
     }else{
        $textElement->configure(-size=>$maxFontSize);
     }
  }
}#sub $text_zoomIn_zoomOut

