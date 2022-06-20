#! /bin/env python3

import time
from multiprocessing import Process
import re
import argparse

parser = argparse.ArgumentParser(description='filter fasta sequences according to quality criteria')
debugmode = parser.add_mutually_exclusive_group()
debugmode.add_argument('-v', '--verbose', action='store_true')
debugmode.add_argument('-q', '--quiet', action='store_true')
parser.add_argument('--version', action='version', version='0.0.1')
parser.add_argument('-t', '--threads', help='number of threads')
parser.add_argument('-i', '--input', help='path to input file')
parser.add_argument('-o', '--output', help='path to output file')
parser.add_argument('-p', '--mincoverage', help='minimum sequence coverage')
parser.add_argument('-l', '--reflength', help='reference genome reflength')

if __name__ == '__main__':
    args = parser.parse_args()

def interval(complete_fasta, threads):
    """
    This function permits to split fasta sequences in intervals according to the number of threads used in multiprocessing
    It creates a list of tuples (interval start, interval end)
    """
    seq_nb=len(complete_fasta)
    seqlength_interval=seq_nb/threads #split in equal parts
    seqlength_interval=int(seqlength_interval) #possible issue with odd thread number
    if seqlength_interval%2 !=0 :
        seqlength_interval=seqlength_interval-1
    lst_interval=[]
    for ite in range(1,threads+1):#begin the interval with index 1 to avoid 0-numbering
        #even seqlength_interval multiplied by an odd number result in an even number
        if ite == 1 : 
            start_interval=0 #using lists, headers will be even numbered
            stop_interval=(seqlength_interval*ite)-1 #right before the start of next thread

        elif ite < threads :
            start_interval=(seqlength_interval)*(ite-1) #give an even number
            stop_interval=(seqlength_interval*ite)-1

        elif ite == threads: #max threads number is reached
            if seqlength_interval*ite != seq_nb : #if not reached, the last interval will be larger
                start_interval=(seqlength_interval)*(ite-1)
                stop_interval=seq_nb-1
            else :
                start_interval=(seqlength_interval)*(ite-1)
                stop_interval=(seqlength_interval*ite)-1
        else :
            print("Issue encountered, please report on github")
        intervalle=(int(start_interval),int(stop_interval))
        lst_interval.append(intervalle)
    return lst_interval

def writefile(file_output,text2write):
    """
    This function write tuples list in the output file without overwriting
    """
    with open(file_output, "a") as file :
        for line in text2write :
            file.write(line)

def readInterval(fastaSeq, start, stop, output, mincoverage, reflength):
    """
    This function Filter determine which sequences should be filtered according to quality criteria
    """
    lst_print=[]
    i=0
    y=0
    for element in range(start,stop+1):
        if re.search('^>',fastaSeq[element]) == None : #verify no ">" is present, hence it is a sequence
            N_nb=fastaSeq[element].count("N")
            seqlength=len(fastaSeq[element])
            if N_nb != 0 : #prevent issues by sequences without any "N" 
                if (seqlength-N_nb)/seqlength > mincoverage and seqlength/reflength > mincoverage : #verify if the sequence reach the mincoverage
                    seq_print=(fastaSeq[element-1]+fastaSeq[element])
                    lst_print.append(seq_print)
                    i+=1
                else :
                    y+=1
            elif N_nb == 0 and seqlength/reflength > mincoverage : #verify if the sequence length is larger than a minimal length
                seq_print=(fastaSeq[element-1] + fastaSeq[element])
                lst_print.append(seq_print)
                i+=1            
            else :
                y+=1
        else :
            pass
    print(f'{i} sequences were retained')
    print(f'{y} sequences were filtered according to the quality criteria') 
    writefile(output,lst_print)

### script ####

file = args.input
output= args.output
threads= int(args.threads)
mincoverage=float(args.mincoverage)
reflength=int(args.reflength)

start_time=time.perf_counter()

processes=[]

with open(file, 'r') as filein :
    complete_file=filein.readlines()

x=interval(complete_file,threads)

for i in range(threads): #launch each process in a different interval
    p=Process(target=readInterval,args=(complete_file,x[i][0],x[i][1],output,mincoverage,reflength))
    p.start()
    processes.append(p)

for process in processes: #close processes
    process.join()
  
stop_time=time.perf_counter()
print(f'Elapsed time : {round(stop_time-start_time,2)} seconds')