#!/usr/bin/env python

'''
Binning preparation of contigs from assembly/coassembly.

Authors: Carmen Saenz, Mani Arumugam
'''

import snakemake

include: 'include/cmdline_validator.smk'
include: 'include/fasta_bam_helpers.smk'

module print_versions:
    snakefile:
        'include/versions.smk'
    config: config

use rule binning_preparation_base, binning_preparation_avamb from print_versions as version_*

snakefile_name = print_versions.get_smk_filename()

localrules: check_depth_batches, combine_contigs_depth_batches, combine_fasta_batches, \
            combine_fasta, check_depths, combine_depth, config_yml_binning, \
            make_abundance_npz

#
# configuration yaml file
# import sys
from os import path
import math

# args = sys.argv
# config_path = args[args.index("--configfile") + 1]
config_path = 'configuration yaml file' #args[args_idx+1]
print(" *******************************")
print(" Reading configuration yaml file")#: , config_path)
print(" *******************************")
print("  ")

# Variables from configuration yaml file

# some variables
if config['PROJECT'] is None:
    print('ERROR in ', config_path, ': PROJECT variable is empty. Please, complete ', config_path)
else:
    project_name = config['PROJECT']

if config['working_dir'] is None:
    print('ERROR in ', config_path, ': working_dir variable is empty. Please, complete ', config_path)
elif path.exists(config['working_dir']) is False:
    print('ERROR in ', config_path, ': working_dir variable path does not exit. Please, complete ', config_path)
else:
    working_dir = config['working_dir']

if config['minto_dir'] is None:
    print('ERROR in ', config_path, ': minto_dir variable in configuration yaml file is empty. Please, complete ', config_path)
elif path.exists(config['minto_dir']) is False:
    print('ERROR in ', config_path, ': minto_dir variable path does not exit. Please, complete ', config_path)
else:
    minto_dir=config["minto_dir"]
    script_dir=config["minto_dir"]+"/scripts/"

if config['METADATA'] is None:
    print('WARNING in ', config_path, ': METADATA variable is empty. Samples will be analyzed excluding the metadata.')
    metadata=config["METADATA"]
elif config['METADATA'] == "None":
    print('WARNING in ', config_path, ': METADATA variable is empty. Samples will be analyzed excluding the metadata.')
    metadata=config["METADATA"]
elif path.exists(config['METADATA']) is False:
    print('ERROR in ', config_path, ': METADATA variable path does not exit. Please, complete ', config_path)
else:
    metadata=config["METADATA"]

if config['MIN_FASTA_LENGTH'] is None:
    print('ERROR in ', config_path, ': MIN_FASTA_LENGTH variable is empty. Please, complete ', config_path)
elif type(config['MIN_FASTA_LENGTH']) != int:
    print('ERROR in ', config_path, ': MIN_FASTA_LENGTH variable is not an integer. Please, complete ', config_path)

# Scaffold type
SCAFFOLDS_type = list()
# Make list of illumina samples, if ILLUMINA in config
ilmn_samples = list()
if 'ILLUMINA' in config:
    if config['ILLUMINA'] is None:
        print('ERROR in ', config_path, ': ILLUMINA list of samples is empty. Please, complete ', config_path)
    else:
        SCAFFOLDS_type.append('illumina_single')
        #print("Samples:")
        for ilmn in config["ILLUMINA"]:
            #print(" "+ilmn)
            ilmn_samples.append(ilmn)
else:
    print('WARNING in ', config_path, ': ILLUMINA list of samples is empty. Skipping short-reads assembly.')

if type(config['METASPADES_hybrid_max_k']) != int or config['METASPADES_hybrid_max_k']%2==0:
    print('ERROR in ', config_path, ': METASPADES_hybrid_max_k variable must be an odd integer')
elif 'METASPADES_custom_build' in config:
    if config['METASPADES_hybrid_max_k'] < 300:
        hybrid_max_k = config['METASPADES_hybrid_max_k']
    else:
        print('ERROR in ', config_path, ': METASPADES_hybrid_max_k variable must be below 300.')
else:
    if config['METASPADES_hybrid_max_k'] < 128:
        hybrid_max_k = config['METASPADES_hybrid_max_k']
    else:
        print('ERROR in ', config_path, ': METASPADES_hybrid_max_k variable must be below 128.')

if type(config['METASPADES_illumina_max_k']) != int or config['METASPADES_illumina_max_k']%2==0:
    print('ERROR in ', config_path, ': METASPADES_illumina_max_k variable must be an odd integer')
elif 'METASPADES_custom_build' in config:
    if config['METASPADES_illumina_max_k'] < 300:
        illumina_max_k = config['METASPADES_illumina_max_k']
    else:
        print('ERROR in ', config_path, ': METASPADES_illumina_max_k variable must be below 300.')
else:
    if config['METASPADES_illumina_max_k'] < 128:
        illumina_max_k = config['METASPADES_illumina_max_k']
    else:
        print('ERROR in ', config_path, ': METASPADES_illumina_max_k variable must be below 128.')

if config['MEGAHIT_presets'] is None and config['MEGAHIT_custom'] is None:
    print('ERROR in ', config_path, ': MEGAHIT_presets list of MEGAHIT parameters to run per co-assembly is empty. Please, complete ', config_path)

if 'MEGAHIT_custom' not in config:
    config['MEGAHIT_custom'] = None
elif config['MEGAHIT_custom'] is not None:
    # if the custom k-s are set, that should be added to the MEGAHIT assembly types
    if isinstance(config['MEGAHIT_custom'], str):
        config['MEGAHIT_custom'] = [config['MEGAHIT_custom']]
    for i, k_list in enumerate(config['MEGAHIT_custom']):
        if k_list and not k_list.isspace():
            if config['MEGAHIT_presets'] is None:
                config['MEGAHIT_presets'] = [f'meta-custom-{i+1}']
            else:
                config['MEGAHIT_presets'].append(f'meta-custom-{i+1}')

batch_size = 100
if config['CONTIG_MAPPING_BATCH_SIZE'] is None:
    print('ERROR in ', config_path, ': CONTIG_MAPPING_BATCH_SIZE variable is empty. Please, complete ', config_path)
elif type(config['CONTIG_MAPPING_BATCH_SIZE']) != int:
    print('ERROR in ', config_path, ': CONTIG_MAPPING_BATCH_SIZE variable is not an integer. Please, complete ', config_path)
else:
    batch_size = config['CONTIG_MAPPING_BATCH_SIZE']

spades_contigs_or_scaffolds = "scaffolds"
if config['SPADES_CONTIGS_OR_SCAFFOLDS'] in ('contigs', 'contig', 'scaffolds', 'scaffold'):
    spades_contigs_or_scaffolds = config['SPADES_CONTIGS_OR_SCAFFOLDS']

if config['BWA_threads'] is None:
    print('ERROR in ', config_path, ': BWA_threads variable is empty. Please, complete ', config_path)
elif type(config['BWA_threads']) != int:
    print('ERROR in ', config_path, ': BWA_threads variable is not an integer. Please, complete ', config_path)

if config['SAMTOOLS_sort_perthread_memgb'] is None:
    print('ERROR in ', config_path, ': SAMTOOLS_sort_perthread_memgb variable is empty. Please, complete ', config_path)
elif type(config['SAMTOOLS_sort_perthread_memgb']) != int:
    print('ERROR in ', config_path, ': SAMTOOLS_sort_perthread_memgb variable is not an integer. Please, complete ', config_path)

# Make list of nanopore assemblies, if NANOPORE in config
nanopore_assemblies = list()
if 'NANOPORE' in config:
    if config['NANOPORE'] is None:
        print('ERRROR in ', config_path, ': NANOPORE list of samples is empty. Please, complete ', config_path)
    else:
        #print("Nanopore assemblies:")
        SCAFFOLDS_type.append('nanopore')
        for nano in config["NANOPORE"]:
            #print(" "+nano)
            nanopore_assemblies.append(nano)
else:
    print('WARNING in ', config_path, ': NANOPORE list of samples is empty. Skipping long-reads assembly.')

# Make list of nanopore-illumina hybrid assemblies, if HYBRID in config
hybrid_assemblies = list()
if 'HYBRID' in config:
    if config['HYBRID'] is None:
        print('ERROR in ', config_path, ': HYBRID list of samples is empty. Please, complete ', config_path)
    else:
        #print("Hybrid assemblies:")
        SCAFFOLDS_type.append('illumina_single_nanopore')
        for nano in config["HYBRID"]:
            for ilmn in config["HYBRID"][nano].split("+"):
                #print(" "+nano+"-"+ilmn)
                hybrid_assemblies.append(nano+"-"+ilmn)
else:
    print('WARNING in ', config_path, ': HYBRID list of samples is empty. Skipping hybrid assembly.')

# Make list of illumina coassemblies, if COASSEMBLY in config
co_assemblies = list()
if 'enable_COASSEMBLY' in config and config['enable_COASSEMBLY'] is not None and config['enable_COASSEMBLY'] is True:
    if 'COASSEMBLY' in config:
        if config['COASSEMBLY'] is None:
            print('ERROR in ', config_path, ': COASSEMBLY list of samples is empty. Please, complete ', config_path)
        else:
            #print("Coassemblies:")
            SCAFFOLDS_type.append('illumina_coas')
            for co in config["COASSEMBLY"]:
                #print(" "+co)
                co_assemblies.append(co)
else:
    print('WARNING in ', config_path, ': COASSEMBLY list of samples is empty. Skipping co-assembly.')

# Initialize some variables

possible_assembly_types = ['illumina_single_nanopore', 'nanopore', 'illumina_coas', 'illumina_single']

# List of assemblies per type
assemblies = {}
assemblies['illumina_single_nanopore'] = hybrid_assemblies
assemblies['nanopore']                 = nanopore_assemblies
assemblies['illumina_coas']            = co_assemblies
assemblies['illumina_single']          = ilmn_samples

# Remove assembly types if specified

if 'EXCLUDE_ASSEMBLY_TYPES' in config:
    if config['EXCLUDE_ASSEMBLY_TYPES'] is not None:
        for item in config['EXCLUDE_ASSEMBLY_TYPES']:
            if item in SCAFFOLDS_type:
                SCAFFOLDS_type.remove(item)

# Site customization for avoiding NFS traffic during I/O heavy steps such as mapping

CLUSTER_NODES            = None
CLUSTER_LOCAL_DIR        = None
CLUSTER_WORKLOAD_MANAGER = None
include: minto_dir + '/site/cluster_def.py'

# Cluster-aware bwa-index rules

include: 'include/bwa_index_wrapper.smk'

# Define all the outputs needed by target 'all'

rule all:
    input:
        abundance = "{wd}/{omics}/8-1-binning/scaffolds.{min_seq_length}.abundance.npz".format(
                wd = working_dir,
                omics = config['omics'],
                min_seq_length = config['MIN_FASTA_LENGTH']),
        config_yaml = "{wd}/{omics}/mags_generation.yaml".format(
                wd = working_dir,
                omics = config['omics']),
        versions = print_versions.get_version_output(snakefile_name)
    default_target: True

###############################################################################################
# Filter contigs from
#  1. MetaSPAdes-individual-assembled illumina samples,
#  2. MEGAHIT-co-assembled illumina samples,
#  3. MetaSPAdes-hybrid-assembled illumina+nanopore data,
#  4. MetaFlye-assembled nanopore sequences
###############################################################################################

def get_assemblies_for_scaf_type(wildcards):
    if (wildcards.scaf_type == 'nanopore'):
        asms = expand("{wd}/{omics}/7-assembly/{assembly}/{assembly_preset}/{assembly}.assembly.fasta",
                            wd = wildcards.wd,
                            omics = wildcards.omics,
                            assembly = assemblies[wildcards.scaf_type],
                            assembly_preset = config['METAFLYE_presets'])
    elif (wildcards.scaf_type == 'illumina_single'):
        asms = expand("{wd}/{omics}/7-assembly/{assembly}/{kmer_dir}/{assembly}.{contig_or_scaffold}.fasta",
                            wd = wildcards.wd,
                            omics = wildcards.omics,
                            assembly = assemblies[wildcards.scaf_type],
                            kmer_dir = "k21-" + str(illumina_max_k),
                            contig_or_scaffold = spades_contigs_or_scaffolds)
    elif (wildcards.scaf_type == 'illumina_coas'):
        asms = expand("{wd}/{omics}/7-assembly/{coassembly}/{assembly_preset}/{coassembly}.contigs.fasta",
                            wd = wildcards.wd,
                            omics = wildcards.omics,
                            coassembly = assemblies[wildcards.scaf_type],
                            assembly_preset = config['MEGAHIT_presets'])
    elif (wildcards.scaf_type == 'illumina_single_nanopore'):
        asms = expand("{wd}/{omics}/7-assembly/{assembly}/{kmer_dir}/{assembly}.{contig_or_scaffold}.fasta",
                            wd = wildcards.wd,
                            omics = wildcards.omics,
                            assembly = assemblies[wildcards.scaf_type],
                            kmer_dir = "k21-" + str(hybrid_max_k),
                            contig_or_scaffold = spades_contigs_or_scaffolds)
    else:
        raise Exception(f"MIntO error: scaf_type={wildcards.scaf_type} is not allowed!")

    return(asms)

checkpoint make_assembly_batches:
    input:
        assemblies = get_assemblies_for_scaf_type
    output:
        location = directory("{wd}/{omics}/8-1-binning/scaffolds_{scaf_type}.{min_length}")
    log:
        "{wd}/logs/{omics}/8-1-binning/scaffolds_{scaf_type}.{min_length}.batching.log"
    wildcard_constraints:
        min_length = r'\d+',
        scaf_type  = r'illumina_single|illumina_coas|illumina_single_nanopore|nanopore'
    resources:
        mem = 5
    params:
        min_length = lambda wildcards: wildcards.min_length
    run:
        import datetime

        def logme(stream, msg):
            print(datetime.datetime.now().strftime("%d/%m/%Y %H:%M:%S"), msg, file=stream)

        with open(str(log), 'w') as f:
            logme(f, "INFO: assemblies={} batch_size={}".format(len(input.assemblies), batch_size))
            for i in range(0, len(input.assemblies), batch_size):
                batch = 1 + int(i/batch_size)
                logme(f, "INFO: Making BATCH={}".format(batch))

                batch_input  = input.assemblies[i:i+batch_size]
                batch_output = output.location + f"/batch{batch}.fasta"
                logme(f, "INFO:   INPUT ={}".format(batch_input))
                logme(f, "INFO:   OUTPUT={}".format(batch_output))

                filter_fasta_list_by_length(batch_input, batch_output, params.min_length)
            logme(f, "INFO: done")

################################################################################################
# Create BWA index for the filtered contigs
################################################################################################

# If CLUSTER_NODES is defined, then return the file symlink'ed to local drives.
# Otherwise, return the original index files in project work_dir.
def get_contig_bwa_index(wildcards):

    # Where are the index files?
    if CLUSTER_NODES != None:
        index_location = 'BWA_index_local'
    else:
        index_location = 'BWA_index'

    # Get all the index files!
    files = expand("{wd}/{omics}/8-1-binning/scaffolds_{scaf_type}.{min_length}/{location}/batch{batch}.fasta.{ext}",
            wd         = wildcards.wd,
            omics      = wildcards.omics,
            scaf_type  = wildcards.scaf_type,
            location   = index_location,
            batch      = wildcards.batch,
            min_length = wildcards.min_length,
            ext        = ['0123', 'amb', 'ann', 'bwt.2bit.64', 'pac'])

    # Return them
    return(files)

# Maps reads to contig-set using bwa2
# Baseline memory usage is:
#   BWA : 3.1 bytes per base in DNA database (regression: mem = 5.556e+09 + 3.011*input)
#   Sort: using config values: SAMTOOLS_sort_threads and SAMTOOLS_sort_perthread_memgb;
#   Total = BWA + Sort
#   E.g. 25GB for BWA, 2 sort threads and 10GB per-thread = 45GB
# If an attempt fails, 30GB extra per sort thread + 30GB extra for BWA.
# Threads for individual tasks: Work backwards from {threads} from snakemake
# Once mapping succeeds, run coverM to get contig depth for this bam

rule map_contigs_BWA_depth_coverM:
    input:
        bwaindex=get_contig_bwa_index,
        fwd='{wd}/{omics}/6-corrected/{illumina}/{illumina}.1.fq.gz',
        rev='{wd}/{omics}/6-corrected/{illumina}/{illumina}.2.fq.gz'
    output:
        depth="{wd}/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/batch{batch}/{illumina}.depth.txt.gz"
    shadow:
        "minimal"
    log:
        "{wd}/logs/{omics}/6-mapping/{illumina}/{illumina}.scaffolds_{scaf_type}.{min_length}.batch{batch}.bwa2.log"
    wildcard_constraints:
        batch    = r'\d+',
        illumina = r'[^/]+'
    resources:
        samtools_sort_threads = 3,
        map_threads = lambda wildcards, threads: max(1, threads - 3),
        coverm_threads = lambda wildcards, threads: min(8, threads),
        mem = lambda wildcards, input, attempt: int(10 + 3.1*os.path.getsize(input.bwaindex[0])/1e9 + 1.1*3*(config['SAMTOOLS_sort_perthread_memgb'] + 30*(attempt-1))),
        sort_mem = lambda wildcards, attempt: config['SAMTOOLS_sort_perthread_memgb'] + 30*(attempt-1)
    threads:
        config['BWA_threads'] + 3
    conda:
        config["minto_dir"]+"/envs/MIntO_base.yml" #bwa-mem2
    shell:
        """
        mkdir -p $(dirname {output})
        db_name=$(echo {input.bwaindex[0]} | sed "s/.0123//")
        time (bwa-mem2 mem -P -a -t {resources.map_threads} $db_name {input.fwd} {input.rev} \
                | msamtools filter -buS -p 95 -l 45 - \
                | samtools sort -m {resources.sort_mem}G --threads {resources.samtools_sort_threads} - \
                > {wildcards.illumina}.bam
              coverm contig --methods metabat --trim-min 10 --trim-max 90 --min-read-percent-identity 95 --threads {resources.coverm_threads} --output-file sorted.depth --bam-files {wildcards.illumina}.bam
              gzip sorted.depth
              rsync -a sorted.depth.gz {output.depth}
        ) >& {log}
        """

# Combine coverM depths from individual samples
# I use python code passed from STDIN within "shell" so that I can use conda env.
rule combine_contig_depths_for_batch:
    input:
        depths = lambda wildcards: expand("{wd}/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/batch{batch}/{illumina}.depth.txt.gz",
                                            wd = wildcards.wd,
                                            omics = wildcards.omics,
                                            scaf_type = wildcards.scaf_type,
                                            min_length = wildcards.min_length,
                                            batch = wildcards.batch,
                                            illumina=ilmn_samples)
    output:
        depths="{wd}/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/batch{batch}.depth.txt.gz",
    log:
        "{wd}/logs/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/batch{batch}.depth.log"
    wildcard_constraints:
        batch = r'\d+',
    shadow:
        "minimal"
    resources:
        mem = lambda wildcards, input: 5+len(input.depths)*0.1
    threads:
        2
    run:
        import pandas as pd
        import hashlib
        import pickle
        import datetime
        import shutil

        def logme(stream, msg):
            print(datetime.datetime.now().strftime("%d/%m/%Y %H:%M:%S"), msg, file=stream)

        with open(str(log), 'w') as f:
            df_list = list()
            logme(f, "INFO: reading file 0")
            df = pd.read_csv(input.depths[0], header=0, sep = "\t", memory_map=True)
            df_list.append(df)
            md5_first = hashlib.md5(pickle.dumps(df.iloc[:, 0:2])).hexdigest() # make hash for seqname and seqlen
            for i in range(1, len(input.depths)):
                logme(f, "INFO: reading file {}".format(i))
                df = pd.read_csv(input.depths[i], header=0, sep = "\t", memory_map=True)
                md5_next = hashlib.md5(pickle.dumps(df.iloc[:, 0:2])).hexdigest()
                if md5_next != md5_first:
                    raise Exception("combine_contig_depths_for_batch: Sequences don't match between {} and {}".format(input.depths[0], input.depths[i]))
                df_list.append(df.drop(['contigName', 'contigLen', 'totalAvgDepth'], axis=1))
            logme(f, "INFO: concatenating {} files".format(len(input.depths)))
            df = pd.concat(df_list, axis=1, ignore_index=False, copy=False, sort=False)
            logme(f, "INFO: writing to temporary file")
            df.to_csv('depths.gz', sep = "\t", index = False, compression={'method': 'gzip', 'compresslevel': 1})
            logme(f, "INFO: copying to final output")
            shutil.copy2('depths.gz', output.depths)
            logme(f, "INFO: done")

##################################################
# Combining across batches within a scaffold_type
##################################################

def get_fasta_batches_for_scaf_type(wildcards):
    checkpoint_output = checkpoints.make_assembly_batches.get(**wildcards).output[0]
    result = expand("{wd}/{omics}/8-1-binning/scaffolds_{scaf_type}.{min_length}/batch{batch}.fasta",
                    wd=wildcards.wd,
                    omics = wildcards.omics,
                    scaf_type = wildcards.scaf_type,
                    min_length = wildcards.min_length,
                    batch=glob_wildcards(os.path.join(checkpoint_output, 'batch{batch}.fasta')).batch)
    return(result)

def get_depth_batches_for_scaf_type(wildcards):
    checkpoint_output = checkpoints.make_assembly_batches.get(**wildcards).output[0]
    result = expand("{wd}/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/batch{batch}.depth.txt.gz",
                    wd=wildcards.wd,
                    omics = wildcards.omics,
                    scaf_type = wildcards.scaf_type,
                    min_length = wildcards.min_length,
                    batch=glob_wildcards(os.path.join(checkpoint_output, 'batch{batch}.fasta')).batch)
    return(result)

# Sanity check to ensure that the order of sample-depths in the depth file is the same. Otherwise binning will be wrong!
rule check_depth_batches:
    input:
        depths = get_depth_batches_for_scaf_type
    output:
        ok="{wd}/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/batches.ok"
    log:
        "{wd}/logs/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/batches.check_depth.log"
    shell:
        """
        rm --force {output}
        uniq_headers=$(for file in {input.depths}; do bash -c "zcat $file | head -1"; done | sort -u | wc -l)
        if [ "$uniq_headers" == "1" ]; then
            touch {output}
        else
            # Headers were not unique. So report and set exit code for this rule to non-zero
            >&2 echo "Headers in depth files were not unique - please check depth files"
            test "1" == "2"
        fi
        """

rule combine_contigs_depth_batches:
    input:
        depths = get_depth_batches_for_scaf_type,
        ok = rules.check_depth_batches.output.ok
    output:
        depths="{wd}/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/combined.depth.txt",
    shadow:
        "minimal"
    params:
        multi = lambda wildcards, input: "yes" if len(input.depths) > 1 else "no"
    resources:
       mem = 10
    threads:
        1
    shell:
        """
        if [ "{params.multi}" == "yes" ]; then
            bash -c "zcat {input.depths[0]} | head -1" > combined.depth
            (for file in {input.depths}; do zcat $file | tail -n +2; done) >> combined.depth
        else
            zcat {input[0]} > combined.depth
        fi
        rsync -a combined.depth {output.depths}
        """


# Combine multiple fasta files from batches into one per scaf_type
rule combine_fasta_batches:
    input:
        fasta = get_fasta_batches_for_scaf_type
    output:
        fasta_combined="{wd}/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/combined.fasta"
    wildcard_constraints:
        min_length = r'\d+',
        scaf_type  = r'illumina_single|illumina_coas|illumina_single_nanopore|nanopore'
    shadow:
        "minimal"
    params:
        multi = lambda wildcards, input: "yes" if len(input.fasta) > 1 else "no"
    resources:
       mem = 10
    threads:
        1
    shell:
        """
        if [ "{params.multi}" == "yes" ]; then
            cat {input} > combined.fasta
            rsync -a combined.fasta {output}
        else
            ln --symbolic --relative --force {input[0]} {output}
        fi
        """

#####################################
# Combining across scaffold_type
#####################################

# Combine multiple fasta files into one
rule combine_fasta:
    input:
        fasta=lambda wildcards: expand("{wd}/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/combined.fasta",
                wd = wildcards.wd,
                omics = wildcards.omics,
                min_length = wildcards.min_length,
                scaf_type = SCAFFOLDS_type)
    output:
        fasta_combined="{wd}/{omics}/8-1-binning/scaffolds.{min_length}.fasta"
    shadow:
        "minimal"
    params:
        multi = lambda wildcards, input: "yes" if len(input.fasta) > 1 else "no"
    resources:
       mem = 10
    threads:
        1
    shell:
        """
        if [ "{params.multi}" == "yes" ]; then
            cat {input} > combined.fasta
            rsync -a combined.fasta {output}
        else
            ln --symbolic --relative --force {input[0]} {output}
        fi
        """

# Sanity check to ensure that the order of sample-depths in the depth file is the same. Otherwise binning will be wrong!
rule check_depths:
    input:
        depths=lambda wildcards: expand("{wd}/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/combined.depth.txt",
                wd = wildcards.wd,
                omics = wildcards.omics,
                min_length = wildcards.min_length,
                scaf_type = SCAFFOLDS_type)
    output:
        ok="{wd}/{omics}/8-1-binning/depths.{min_length}.ok"
    shell:
        """
        rm --force {output}
        uniq_headers=$(for file in {input.depths}; do head -1 $file; done | sort -u | wc -l)
        if [ "$uniq_headers" == "1" ]; then
            touch {output}
        else
            # Headers were not unique. So report and set exit code for this rule to non-zero
            >&2 echo "Headers in depth files were not unique - please check depth files"
            test "1" == "2"
        fi
        """

# Combine multiple depth files into one
rule combine_depth:
    input:
        depths=lambda wildcards: expand("{wd}/{omics}/8-1-binning/depth_{scaf_type}.{min_length}/combined.depth.txt",
                wd = wildcards.wd,
                omics = wildcards.omics,
                min_length = wildcards.min_length,
                scaf_type = SCAFFOLDS_type),
        depth_ok = rules.check_depths.output.ok
    output:
        depth_combined="{wd}/{omics}/8-1-binning/scaffolds.{min_length}.depth.txt"
    shadow:
        "minimal"
    params:
        multi = lambda wildcards, input: "yes" if len(input.depths) > 1 else "no"
    resources:
       mem = 10
    threads:
        1
    shell:
        """
        if [ "{params.multi}" == "yes" ]; then
            head -1 {input.depths[0]} > combined.depth
            (for file in {input.depths}; do tail -n +2 $file; done) >> combined.depth
            rsync -a combined.depth {output}
        else
            ln --symbolic --relative --force {input[0]} {output}
        fi
        """

### Prepare abundance.npz for avamb v4+
rule make_abundance_npz:
    input:
        contigs_file = rules.combine_fasta.output.fasta_combined,
        depth_file = rules.combine_depth.output.depth_combined
    output:
        npz="{wd}/{omics}/8-1-binning/scaffolds.{min_length}.abundance.npz"
    log:
        "{wd}/logs/{omics}/8-1-binning/scaffolds.{min_length}.abundance.log"
    threads:
        1
    conda:
        config["minto_dir"]+"/envs/avamb.yml"
    shell:
        """
        time (
            python {script_dir}/make_vamb_abundance_npz.py --fasta {input.contigs_file} --jgi {input.depth_file} --output {output.npz} --samples {ilmn_samples}
        ) >& {log}
        """

###############################################################################################
# Generate configuration yml file for recovery of MAGs and taxonomic annotation step - binning
###############################################################################################

rule config_yml_binning:
    output:
        config_file="{wd}/{omics}/mags_generation.yaml",
    resources:
        mem=2
    threads: 2
    log:
        "{wd}/logs/{omics}/config_yml_mags_generation.log"
    params:
        min_fasta_length=config['MIN_FASTA_LENGTH']
    shell:
        """
        time (echo "######################
# General settings
######################
PROJECT: {project_name}
working_dir: {wildcards.wd}
omics: {wildcards.omics}
minto_dir: {minto_dir}
METADATA: {metadata}

######################
# Program settings
######################
# COMMON PARAMETERS
#
MIN_FASTA_LENGTH: {params.min_fasta_length}
MIN_MAG_LENGTH: 500000

# VAMB settings
#
BINNERS:
- aaey
- aaez
- vae384

VAMB_THREADS: 20
VAMB_memory: 40

# Use GPU in VAMB:
# could be yes or no
VAMB_GPU: no


# CHECKM settings
#
CHECKM_COMPLETENESS: 90  # higher than this
CHECKM_CONTAMINATION: 5  # lower than this
CHECKM_BATCH_SIZE: 50    # Process MAGs with this batch size

# COVERM settings
#
COVERM_THREADS: 8
COVERM_memory: 5

# SCORING THE BEST GENOMES settings
#
# this could be checkm or genome
SCORE_METHOD: checkm
" > {output.config_file}

) >& {log}
        """
