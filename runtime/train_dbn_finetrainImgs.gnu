### Expected arguments
## i=[int]
## run_id=[str]

### Example code
# for i in {0..700};
#     do echo "gnuplot -e run_id='train_dbn';i='$(printf "%03d" $i)'\
#     runtime/train_dbn_finetrainImgs.gnu";
#     sleep 5;
# done
###

### files
base_loc = "dump/data/".run_id."_"
plot_loc = "dump/plots/".run_id."_"
ext = ".dat"

# grab all the files using a glob pattern
cost_files = system("ls ".base_loc."cost_"."*".ext)
params_files = system("ls ".base_loc."params_"."*".ext)
updates_files = system("ls ".base_loc."updates_"."*".ext)
weight_file = system("ls ".plot_loc."*weights"."*".ext)

# get the string names to label the plots from the filenames using REGEX
params_names = system("ls ".base_loc."params_"."*".ext." | sed -e 's#".base_loc."params_"."\\(.*\\)\\".ext."#\\1#' -e 's#_# #g'")
updates_names = system("ls ".base_loc."params_"."*".ext." | sed -e 's#".base_loc."params_"."\\(.*\\)\\".ext."#\\1#' -e 's#_# #g'")

#function used to map a value to the intervals
hist(x,width)=width*floor(x/width)+width/2.0

## number of standard deviations to show in histogram
hw=3

## number of boxes in histogram
n=25

# this is the number of paramters (width of the plot)
# number of dbn layers * 2 (w,b) params per layer at finetrainining
xn=8

# this is the height of the plot i.e. 
# + 2 for the cost
# + 1 for values
# + 1 for histogram of values
# + 1 for histogram of updates
yn = 2+1+1+1

# not sure why I did this next two lines. Might have been drunk.
x = xn
y = yn

# this is the offset around the boarders
o = 0.1

# again I think I may have been drunk
xi = o
yi = o

# final and initial values for plotting
xf = x-o
xs = xf-xi
yf = y-o
ys = yf-yi

### Start multiplot
set encoding utf8
set terminal png size 1440,800 enhanced font 'Verdana,6'
set output plot_loc."finetrainImgs_".iter.".png"

set multiplot
set autoscale x

# --- GRAPH input image
unset key
unset key
unset colorbox
unset tics
unset xlabel
unset ylabel
set size (xs/2.)/x,2*ys/yn/y
set origin (xi+(xs/2.))/x,(yi+3*ys/yn)/y
set border linewidth 0
set palette grey

f = word(weight_file, 1)
set title "input weights" font ",8"
plot f matrix w image

# --- GRAPH cost
unset key
set tics
f = word(cost_files, 1)

set size (xs/2.)/x,2*ys/yn/y
set origin xi/x,(yi+3*ys/yn)/y

set title "<cost> vs. training samples" font ",8"
set xlabel "sample" font ",8"
set ylabel "<Cost>" font ",8"
plot f u (column(0)):1 w l ls 1 lc rgb"blue"

set xtics rotate by -45
# --- GRAPH params per batch
do for [i=1:words(params_files)] {
    unset key
    p = word(params_names,i*2-1)." ".word(params_names,i*2)
    f = word(params_files, i)
    
    set size (xs/xn)/x,(ys/yn)/y
    set origin (xi+(i-1)*(xs/xn))/x,(yi+2*ys/yn)/y
    set tics
    
    set title p.", <X_".i.">" font ",8"
    set xlabel "sample" font ",8"
    set ylabel "<X_".i.">" font ",8"
    plot f u (column(0)):1 with lines ls 1
}

# --- GRAPH histogram of params
do for [i=1:words(params_files)] {
    unset key
    p = word(params_names,i*2-1)." ".word(params_names,i*2)
    f = word(params_files, i)
    
    if (f ne ""){
        stats f using 1 nooutput
        if (STATS_min != STATS_max){
            set tics
            set size (xs/xn)/x,(ys/yn)/y
            set origin (xi+(i-1)*(xs/xn))/x,(yi+1*ys/yn)/y
            
            max=STATS_mean+hw*STATS_stddev #max value
            min=STATS_mean-hw*STATS_stddev #min value
            width=(max-min)/n #interval width
            set xrange [min:max]
            
            set style fill solid noborder
            set boxwidth width*0.9
            
            set title "Freq. of <X_".i.">" font ",8"
            set xlabel "<X_".i.">" font ",8"
            set ylabel "freq" font ",8"
            
            plot f u (hist($1,width)):(1.0/STATS_records) \
                smooth freq w boxes lc rgb"green" notitle
        } else {
            print "Update Hist: ".p.": cannot plot... all equal to: ",\
                STATS_min
        }
    } else {
        print "file being updated..."
    }
}
# --- GRAPH histogram of learning updates
do for [i=1:words(updates_files)] {
    unset key
    p = word(updates_names,i*2-1)." ".word(updates_names,i*2)
    f = word(updates_files, i)
    
    if (f ne ""){
        stats f using 1 nooutput
        if (STATS_min != STATS_max){
            set tics
            set size (xs/xn)/x,(ys/yn)/y
            set origin (xi+(i-1)*(xs/xn))/x,(yi+0*ys/yn)/y
            
            max=STATS_mean+hw*STATS_stddev #max value
            min=STATS_mean-hw*STATS_stddev #min value
            width=(max-min)/n #interval width
            set xrange [min:max]
            
            set style fill solid noborder
            set boxwidth width*0.9
            
            set title "Freq. of <-{/Symbol D}X_".i.">" font ",8"
            set xlabel "<X_".i.">" font ",8"
            set ylabel "freq" font ",8"
            plot f u (hist($1,width)):(1.0/STATS_records) \
                smooth freq w boxes lc rgb"red" notitle
        } else {
            print "Update Hist: ".p.": cannot plot... all equal to: ",\
                STATS_min
        }
    } else {
        print "file being updated..."
    }
}

unset multiplot
### End multiplot