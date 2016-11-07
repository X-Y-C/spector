#!/usr/bin/python

# ----------------------------------------------------------------------
# Copyright (c) 2016, The Regents of the University of California All
# rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
# 
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
# 
#     * Neither the name of The Regents of the University of California
#       nor the names of its contributors may be used to endorse or
#       promote products derived from this software without specific
#       prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL REGENTS OF THE
# UNIVERSITY OF CALIFORNIA BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.
# ----------------------------------------------------------------------
# Filename: 1_compile.py
# Version: 1.0
# Description: Python script to generate unique designs for the DCT benchmark.
# Author: Quentin Gautier


import os
import sys
import shutil
import subprocess
import multiprocessing as mp


srcFolder = "../src"
scriptsFolder = "."
benchmarksFolder = "../benchmarks"

clGenScript = "dct_cl_gen.py"
compileScripts = ["dct_synthesize" + str(i) + ".sh" for i in range(13)]



def runScript(script, path):    
    subprocess.call("./" + script, cwd=path, shell=True)
    

def runScriptMap(scriptpath):
    runScript(scriptpath[0], scriptpath[1])



def main():

    # Get number of processors
    num_processes = 0
    if len(sys.argv) >= 2:
    	num_processes = int(sys.argv[1])
    
    if num_processes > 0:
    	print("Using " + str(num_processes) + " processes")
    else:
    	print("Using all available processes")


    print("Copying files...")

    # Copy source files
    for f in os.listdir(srcFolder):
        if os.path.isfile(os.path.join(srcFolder, f)):
            shutil.copy(
                    os.path.join(srcFolder, f),
                    os.path.join(benchmarksFolder, f))

    # Copy cl_gen script
    shutil.copy(
            os.path.join(scriptsFolder, clGenScript),
            os.path.join(benchmarksFolder, clGenScript))

    # Copy compile scripts
    for s in compileScripts:        
        shutil.copy(
                os.path.join(scriptsFolder, s),
                os.path.join(benchmarksFolder, s))

    # Generate OpenCL files
    print("Generating OpenCL files...")
    runScript(clGenScript, benchmarksFolder)
    
    
    # Compile OpenCL files
    print("Compiling all OpenCL files...")
    if num_processes > 0:
    	pool = mp.Pool(num_processes)
    else:
    	pool = mp.Pool()
    
    result = pool.map_async(runScriptMap, list(zip(compileScripts, [benchmarksFolder]*len(compileScripts)))).get(31536000) # timeout of 365 days


    print("Done.")

if __name__ == "__main__":
    main()






