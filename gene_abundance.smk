#!/usr/bin/env python

'''
Alignment, normalization and integration step

Authors: Carmen Saenz
'''

# snakemake --snakefile /emc/cbmr/users/rzv923/MIntO/gene_abundance.smk --cluster "qsub -pe smp {threads} -l h_vmem={resources.mem}G -N {name} -cwd" --latency-wait 60 --jobs 3 --configfile mapping.smk.yaml --use-conda --conda-prefix /emc/cbmr/users/rzv923/ibdmdb/tmp_porus/
# snakemake --snakefile /emc/cbmr/users/rzv923/MIntO/gene_abundance.smk --restart-times 0 --keep-going --latency-wait 30 --cluster "sbatch -J {name} --mem={resources.mem}G -c {threads} -e slurm-%x.e%A -o slurm-%x.o%A" --configfile mapping.smk.yaml --use-conda --conda-prefix /emc/cbmr/users/rzv923/ibdmdb/tmp_ironman/ --jobs 8
# snakemake --snakefile /emc/cbmr/users/rzv923/MIntO/gene_abundance.smk --restart-times 0 --keep-going --latency-wait 30 --cluster "sbatch -J {name} --mem={resources.mem}G -c {threads} -e slurm-%x.e%A -o slurm-%x.o%A" --jobs 8 --configfile mapping.smk.yaml --use-singularity

# Make list of illumina samples, if ILLUMINA in config
ilmn_samples = list()
if 'ILLUMINA' in config:
    print("Samples:")
    for ilmn in config["ILLUMINA"]:
            print(ilmn)
            ilmn_samples.append(ilmn)
n_samples=len(ilmn_samples)+3

project_id = config['PROJECT']
working_dir = config['working_dir']
omics = config['omics']
local_dir = config['local_dir']
minto_dir=config["minto_dir"]
script_dir=config["minto_dir"]+"/scripts"

metadata=config["METADATA"]
map_reference=config["map_reference"]
normalization=config['abundance_normalization']
identity=config['alignment_identity']

# Define all the outputs needed by target 'all'
if map_reference == 'MAG':
    post_analysis_dir="9-MAGs-prokka-post-analysis"
    post_analysis_out="MAGs_genes"
    reference_dir="{wd}/metaG/8-1-binning/mags_generation_pipeline/prokka".format(wd = working_dir)
    gene_catalog_name="None"
    bwaindex_db="DB/9-MAGs-prokka-post-analysis/BWA_index/MAGs_genes" #.format(wd = working_dir)
    def gene_abundances_bwa_out():
        result = expand("{wd}/DB/{post_analysis_dir}/{post_analysis_out}.fna",
                    wd = working_dir,
                    post_analysis_dir = "9-MAGs-prokka-post-analysis",
                    post_analysis_out = "MAGs_genes"),\
        expand("{wd}/{bwaindex_path}.pac",
                    wd = working_dir, 
                    bwaindex_path = bwaindex_db),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.bam", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "MAGs_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity,),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.sorted.bam", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "MAGs_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.sorted.bam.bai", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "MAGs_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.log", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "MAGs_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.profile.abund.prop.txt.gz", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "MAGs_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity)
        return(result)

if map_reference == 'reference_genome':
    post_analysis_dir="9-reference-genes-post-analysis"
    post_analysis_out="reference_genes"
    reference_dir=config["PATH_reference"]
    gene_catalog_name="None"
    bwaindex_db="DB/9-reference-genes-post-analysis/BWA_index/reference_genes" #.format(wd = working_dir)
    def gene_abundances_bwa_out():
        result = expand("{wd}/DB/{post_analysis_dir}/{post_analysis_out}.fna",
                    wd = working_dir,
                    post_analysis_dir = "9-reference-genes-post-analysis",
                    post_analysis_out = "reference_genes"),\
        expand("{wd}/{bwaindex_path}.pac", 
                    wd = working_dir,
                    bwaindex_path = bwaindex_db),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.bam", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "reference_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity,),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.sorted.bam", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "reference_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.sorted.bam.bai", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "reference_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.log", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "reference_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.profile.abund.prop.txt.gz", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "reference_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity)

        return(result)

# MAybe put it inside of MAG and reference_genome and genes_db. genes_db only generates tpm normalization, and it's direclty from bwa
if normalization == 'MG': 
    fetchMGs_dir=config["fetchMGs_dir"]
    def gene_abundances_normalization_out():
        result = expand("{wd}/DB/{post_analysis_dir}/all.marker_genes_scores.table", 
                        wd = working_dir,
                        post_analysis_dir = post_analysis_dir),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.MG.csv", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = post_analysis_out,
                    identity = identity)
        return(result)

if normalization == 'TPM': 
    def gene_abundances_normalization_out():
        result = expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.TPM.csv", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = post_analysis_out,
                    identity = identity)
        return(result)

if map_reference == 'genes_db':
    post_analysis_dir="9-genes-db-post-analysis"
    post_analysis_out="db_genes"
    gene_catalog_db=config["PATH_reference"]
    gene_catalog_name=config["NAME_reference"]
    reference_dir="{wd}"
    def gene_abundances_bwa_out(): # CHECK THIS PART - do not generate bwa index, normalization in a different way
        result = expand("{gene_catalog_path}/BWA_index/{gene_catalog_name}.pac", 
                    gene_catalog_path=gene_catalog_db, 
                    gene_catalog_name=gene_catalog_name),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.bam", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "db_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.log", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "db_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity),\
        expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.profile_TPM.txt.gz", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "db_genes",
                    sample = config["ILLUMINA"] if "ILLUMINA" in config else [],
                    identity = identity)
        return(result)
    def gene_abundances_normalization_out():
        #expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.TPM.txt", 
        result = expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.TPM.csv",
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = "db_genes",
                    identity = identity)
        return(result)

if omics == 'metaG':
    hq_dir="4-hostfree"
if omics == 'metaT':
    hq_dir="5-1-sortmerna"

def gene_abundances_map_prof():
    result = expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.txt", 
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = post_analysis_out,
                    identity = identity),\
    expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.maprate.txt",
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = post_analysis_out,
                    identity = identity),\
    expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.mapstats.txt",
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = post_analysis_out,
                    identity = identity),\
    expand("{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.multimap.txt",
                    wd = working_dir,
                    omics = omics,
                    post_analysis_out = post_analysis_out,
                    identity = identity)
    return(result)

def config_yaml():
    result = "{wd}/data_integration.yaml".format(
                wd = working_dir)
    return(result)

rule all:
    input: 
        gene_abundances_bwa_out(),
        gene_abundances_normalization_out(),
        gene_abundances_map_prof(),
        config_yaml()


###############################################################################################
# Prepare genes for mapping to MAGs or publicly available genomes
## Generate MAGs or publicly available genomes index
###############################################################################################
rule gene_abund_bwaindex:
    input: 
        genomes_list="{wd}/DB/{post_analysis_dir}/genomes_list.txt",
        in_dir="{input_dir}/".format(input_dir=reference_dir),
    output: 
        fasta_genomes_merge="{wd}/DB/{post_analysis_dir}/{post_analysis_out}.fna", 
        bwaindex="{wd}/DB/{post_analysis_dir}/BWA_index/{post_analysis_out}.pac"
    params:
        tmp_bwaindex=lambda wildcards: "{local_dir}/{post_analysis_out}_bwaindex/".format(local_dir=local_dir, post_analysis_out=post_analysis_out),
        indexprefix="{post_analysis_out}",
    log:
        "{{wd}}/logs/{omics}/{{post_analysis_dir}}/{{post_analysis_out}}_bwaindex.log".format(omics = omics)
    threads: config["BWAindex_threads"]
    resources:
        mem=config["BWAindex_memory"]
    conda:
        config["minto_dir"]+"/envs/MIntO_base.yml" #config["conda_env2_yml"]
    shell:
        """
        mkdir -p {wildcards.wd}/DB/{post_analysis_dir}/fasta/
        mkdir -p {params.tmp_bwaindex}BWA_index/; mkdir -p {params.tmp_bwaindex}fasta
        time (cd {reference_dir}
        if [ {map_reference} == 'MAG' ]
            then echo {map_reference}
            for file in */*.fna
                do echo ${{file}}
                genome=$(basename "${{file}}" .fna)
                echo ${{genome}}
                sed -e "1,$ s/^>gnl|X|/>${{genome}}|/g" "${{file}}" > {params.tmp_bwaindex}fasta/${{genome}}.fna
            done
        elif [ {map_reference} == 'reference_genome' ]
            then echo {map_reference}
            for file in */*.fna
                do echo ${{file}}
                genome=$(basename "${{file}}" .fna)
                echo ${{genome}}
                sed -e "1,$ s/^>/>${{genome}}|/g" "${{file}}" > {params.tmp_bwaindex}fasta/${{genome}}.fna
            done
        fi
        for g in $(cat {input.genomes_list})
            do cat {params.tmp_bwaindex}fasta/${{g}}.fna >> {params.tmp_bwaindex}{params.indexprefix}.fna
        done
        bwa-mem2 index {params.tmp_bwaindex}{params.indexprefix}.fna -p {params.tmp_bwaindex}BWA_index/{params.indexprefix}
        rsync {params.tmp_bwaindex}BWA_index/* {wildcards.wd}/DB/{post_analysis_dir}/BWA_index/
        rsync {params.tmp_bwaindex}fasta/* {wildcards.wd}/DB/{post_analysis_dir}/fasta/
        rsync {params.tmp_bwaindex}{params.indexprefix}.fna {output.fasta_genomes_merge}
        rm -rf {params.tmp_bwaindex}) &> {log} """

rule gene_abund_bwa_raw: # Difference between gene_abund_bwa_tpm and gene_abund_bwa_raw # *************************************
    input:
        #bwaindex="{wd}/{bwaindex_path}.pac".format(wd = working_dir, bwaindex_path = bwaindex_db), 
        bwaindex="{wd}/DB/{post_analysis_dir}/BWA_index/{post_analysis_out}.pac".format(wd = working_dir, post_analysis_dir = post_analysis_dir, post_analysis_out = post_analysis_out), 
        hq_reads_fw=lambda wildcards: '{wd}/{omics}/{hq_dir}/{sample}/{sample}.1.fq.gz'.format(wd = working_dir,omics=omics, hq_dir=hq_dir, sample=wildcards.sample),
        hq_reads_rv=lambda wildcards: '{wd}/{omics}/{hq_dir}/{sample}/{sample}.2.fq.gz'.format(wd = working_dir,omics=omics, hq_dir=hq_dir, sample=wildcards.sample),
        #hq_reads_fw=lambda wildcards: '{wd}/{omics}/5-1-sortmerna/{sample}/{sample}.1.fq.gz',
        #hq_reads_rv=lambda wildcards: '{wd}/{omics}/5-1-sortmerna/{sample}/{sample}.2.fq.gz',
    output:
        filter="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.bam",#.format(wd = working_dir, omics = omics, sample = ilmn_samples, identity = identity),
        sort="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.sorted.bam",#.format(wd = working_dir, omics = omics, sample = ilmn_samples, identity = identity),
        index="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.sorted.bam.bai",#.format(wd = working_dir, omics = omics, sample = ilmn_samples, identity = identity),
        bwa_log="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.log",#.format(wd = working_dir, omics = omics, sample = ilmn_samples, identity = identity),
        profile_raw="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.profile.abund.prop.txt.gz",#.format(wd = working_dir, omics = omics, sample = ilmn_samples, identity = identity),
        map_profile="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{identity}.filtered.profile.abund.all.txt.gz"
    params:
        #extra_params=config["BWAalignm_parameters"],
        tmp_bwa=lambda wildcards: "{local_dir}/{omics}_{sample}_{post_analysis_out}_bwa_raw/".format(local_dir=local_dir, omics=omics, sample=wildcards.sample, post_analysis_out=post_analysis_out),
        length=config["msamtools_filter_length"],
        prefix="{sample}.p{identity}.filtered",
        memory=lambda wildcards, resources: resources.mem - 1,
    log:
        "{wd}/logs/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}.p{identity}_bwa.log" #.format(wd = working_dir, omics = omics, sample = ilmn_samples, identity = identity, post_analysis_out=post_analysis_out),
    threads: config["BWA_threads"]
    resources:
        mem=config["BWA_memory"]
    conda:
        config["minto_dir"]+"/envs/MIntO_base.yml" #config["conda_env2_yml"] #BWA + samtools
    shell:
     # from porus:
        """mkdir -p {params.tmp_bwa}
        bwaindex_dir=$(dirname {input.bwaindex})
        remote_dir=$(dirname {output.filter})
        (time (bwa-mem2 mem -a -t {threads} -v 3 ${{bwaindex_dir}}/{post_analysis_out} {input.hq_reads_fw} {input.hq_reads_rv}| \
msamtools filter -S -b -l {params.length} -p {identity} -z 80 --besthit - > {params.tmp_bwa}{params.prefix}.bam) >& {params.tmp_bwa}{params.prefix}.log
        samtools sort {params.tmp_bwa}{params.prefix}.bam -o {params.tmp_bwa}{params.prefix}.sorted.bam -@ {threads} -m {params.memory}G --output-fmt=BAM 
        samtools index {params.tmp_bwa}{params.prefix}.sorted.bam {params.tmp_bwa}{params.prefix}.sorted.bam.bai -@ {threads}
        total_reads="$(grep Processed {params.tmp_bwa}{params.prefix}.log | perl -ne 'm/Processed (\\d+) reads/; $sum+=$1; END{{printf "%d\\n", $sum/2;}}')"
        echo $total_reads
        msamtools profile {params.tmp_bwa}{params.prefix}.bam --label {wildcards.omics}.{wildcards.sample} -o {params.tmp_bwa}{params.prefix}.profile.abund.prop.txt.gz \
--total $total_reads --multi prop --unit abund --nolen
        msamtools profile {params.tmp_bwa}{params.prefix}.bam --label {wildcards.omics}.{wildcards.sample} -o {params.tmp_bwa}{params.prefix}.profile.abund.all.txt.gz \
--total $total_reads --multi all --unit abund --nolen
        rsync {params.tmp_bwa}* ${{remote_dir}}
        rm -rf {params.tmp_bwa}) >& {log}"""
#         # from hulk:
#           /usr/local/bin/samtools
#         # from ironman:
#           /home/rzv923/anaconda3/bin/samtools
###############################################################################################
# Prepare genes for mapping to gene-database
## The index has to be given by the user -NOO
## Mapping, computation of read counts and TPM normalization is done in the same rule
## TPM normalization: sequence depth and the genes’ length 
###############################################################################################
# #TODO
# Change gene_catalog_path and gene_catalog_name in reference_genome mode
# Generate index where reference genomes?
# Try
rule gene_abund_bwaindex_gene_catalog:
    input:
        genes=lambda wildcards: "{gene_catalog_path}/{gene_catalog_name}".format(gene_catalog_path=gene_catalog_db, gene_catalog_name=gene_catalog_name),
    output: 
        bwaindex="{gene_catalog_path}/BWA_index/{gene_catalog_name}.pac".format(gene_catalog_path=gene_catalog_db, gene_catalog_name=gene_catalog_name),
    params:
        tmp_bwaindex=lambda wildcards: "{local_dir}/{gene_catalog_name}_bwaindex/".format(local_dir=local_dir, gene_catalog_name=gene_catalog_name),
    log:
        "{wd}/logs/{omics}/{post_analysis_dir}/{post_analysis_out}_bwaindex.log".format(wd = working_dir, omics=omics, post_analysis_dir=post_analysis_dir , post_analysis_out=post_analysis_out)
    threads: config["BWAindex_threads"]
    resources:
        mem=config["BWAindex_memory"]
    conda:
        config["minto_dir"]+"/envs/MIntO_base.yml" #config["conda_env2_yml"]
    shell:
        """
        mkdir -p {working_dir}/DB/{post_analysis_dir}/fasta/
        mkdir -p {params.tmp_bwaindex}
        time (bwa-mem2 index {gene_catalog_db}/{gene_catalog_name} -p {params.tmp_bwaindex}{gene_catalog_name}
        rsync {params.tmp_bwaindex}* {gene_catalog_db}/BWA_index/
        rm -rf {params.tmp_bwaindex}) &> {log} """
        
rule gene_abund_bwa_tpm:
    input: 
        bwaindex=lambda wildcards: "{gene_catalog_path}/BWA_index/{gene_catalog_name}.pac".format(gene_catalog_path=gene_catalog_db, gene_catalog_name=gene_catalog_name),
        hq_reads_fw=lambda wildcards: '{wd}/{omics}/{hq_dir}/{sample}/{sample}.1.fq.gz'.format(wd = working_dir, omics=omics,hq_dir=hq_dir, sample=wildcards.sample),
        hq_reads_rv=lambda wildcards: '{wd}/{omics}/{hq_dir}/{sample}/{sample}.2.fq.gz'.format(wd = working_dir, omics=omics,hq_dir=hq_dir, sample=wildcards.sample),
    output:
        filter="{wd}/{omics}/6-mapping-profiles/BWA_reads-db_genes/{sample}/{sample}.p{identity}.filtered.bam",
        bwa_log="{wd}/{omics}/6-mapping-profiles/BWA_reads-db_genes/{sample}/{sample}.p{identity}.filtered.log",
        profile_tpm="{wd}/{omics}/6-mapping-profiles/BWA_reads-db_genes/{sample}/{sample}.p{identity}.filtered.profile_TPM.txt.gz",
        map_profile="{wd}/{omics}/6-mapping-profiles/BWA_reads-db_genes/{sample}/{sample}.p{identity}.filtered.profile.abund.all.txt.gz"
    params:
        #extra_params=config["BWAalignm_parameters"],
        tmp_bwa=lambda wildcards: "{local_dir}/{omics}_{sample}_db_genes_bwa_tpm/".format(local_dir=local_dir, omics=omics, sample=wildcards.sample),
        length=config["msamtools_filter_length"],
        prefix="{sample}.p{identity}.filtered",
        memory=lambda wildcards, resources: resources.mem - 1,
        bwaindex="{gene_catalog_path}/BWA_index/{gene_catalog_name}".format(gene_catalog_path=gene_catalog_db, gene_catalog_name=gene_catalog_name)
    log:
        "{wd}/logs/{omics}/6-mapping-profiles/BWA_reads-db_genes/{sample}.p{identity}_bwa.log"#.format(wd = working_dir, omics = omics, sample = ilmn_samples, identity = identity, post_analysis_out=post_analysis_out),
    threads: config["BWA_threads"]
    resources:
        mem=config["BWA_memory"]
    conda:
        config["minto_dir"]+"/envs/MIntO_base.yml" #config["conda_env2_yml"] #BWA + samtools
    shell:
     # from porus:
        """mkdir -p {params.tmp_bwa}
        bwaindex_dir=$(dirname {input.bwaindex})
        remote_dir=$(dirname {output.filter})
        (time (bwa-mem2 mem -a -t {threads} -v 3 {params.bwaindex} {input.hq_reads_fw} {input.hq_reads_rv}| \
msamtools filter -S -b -l {params.length} -p {identity} -z 80 --besthit - > {params.tmp_bwa}{params.prefix}.bam) >& {params.tmp_bwa}{params.prefix}.log
        total_reads="$(grep Processed {params.tmp_bwa}{params.prefix}.log | perl -ne 'm/Processed (\\d+) reads/; $sum+=$1; END{{printf "%d\\n", $sum/2;}}')"
        echo $total_reads
        msamtools profile {params.tmp_bwa}{params.prefix}.bam --label {omics}.{wildcards.sample} -o {params.tmp_bwa}{params.prefix}.profile_TPM.txt.gz \
--total $total_reads --multi prop --unit tpm
        msamtools profile {params.tmp_bwa}{params.prefix}.bam --label {omics}.{wildcards.sample} -o {params.tmp_bwa}{params.prefix}.profile.abund.all.txt.gz \
--total $total_reads --multi all --unit abund --nolen
        rsync {params.tmp_bwa}* ${{remote_dir}} ) >& {log}
        rm -rf {params.tmp_bwa}"""

###############################################################################################
# Computation of read counts to genes belonging to MAGs or publicly available genomes
###############################################################################################

rule gene_abund_compute:
    input: 
        sort=expand("{{wd}}/{{omics}}/6-mapping-profiles/BWA_reads-{{post_analysis_out}}/{sample}/{sample}.p{{identity}}.filtered.sorted.bam", sample=ilmn_samples),
        index=expand("{{wd}}/{{omics}}/6-mapping-profiles/BWA_reads-{{post_analysis_out}}/{sample}/{sample}.p{{identity}}.filtered.sorted.bam.bai", sample=ilmn_samples),
        bed_subset="{wd}/DB/{post_analysis_dir}/{post_analysis_out}_SUBSET.bed".format(wd = working_dir, post_analysis_dir = post_analysis_dir, post_analysis_out=post_analysis_out)
    output: 
        absolute_counts="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.bed"
    params:
        tmp_bwa=lambda wildcards: "{local_dir}/{omics}_{post_analysis_out}_abundances/".format(local_dir=local_dir, omics=omics, post_analysis_out=post_analysis_out),
        prefix="genes_abundances.p{identity}.bed"
    log:
        "{wd}/logs/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances_counts.p{identity}.log"
    threads: config["BWA_threads"]
    resources:
        mem=config["BWA_memory"]
    conda: 
        config["minto_dir"]+"/envs/MIntO_base.yml" #bedtools
    shell:
        """ mkdir -p {params.tmp_bwa}
        time (files='{ilmn_samples}'; echo ${{files}} | tr ' ' '\\t' > {params.tmp_bwa}filename_list
        echo -e 'chr\\tstart\\tstop\\tname\\tscore\\tstrand\\tsource\\tfeature\\tframe\\tinfo' > {params.tmp_bwa}column_names
        cat {params.tmp_bwa}filename_list >> {params.tmp_bwa}column_names; cat {params.tmp_bwa}column_names| tr '\\n' '\\t' > {params.tmp_bwa}column_names2
        sed 's/\t$//' {params.tmp_bwa}column_names2 >> {params.tmp_bwa}{params.prefix}; echo '' >> {params.tmp_bwa}{params.prefix}
        bedtools multicov -bams {input.sort} -bed {input.bed_subset} >> {params.tmp_bwa}{params.prefix}
        rsync {params.tmp_bwa}{params.prefix} {output.absolute_counts}) &> {log}
        rm -rf {params.tmp_bwa}"""

###############################################################################################
# Normalization of read counts to 10 marker genes (MG normalization)
## fetchMGs identifies 10 universal single-copy phylogenetic MGs 
## (COG0012, COG0016, COG0018, COG0172, COG0215, COG0495, COG0525, COG0533, COG0541, and COG0552)
###############################################################################################

# Run fetchMGs
rule gene_abund_marker_genes:
    input: 
        genomes_list="{wd}/DB/{post_analysis_dir}/genomes_list.txt".format(wd = working_dir, post_analysis_dir = post_analysis_dir),
    output:
        fetchMGs_out="{wd}/DB/{post_analysis_dir}/CD_transl/{post_analysis_out}_fetchMGs_translated_cds_SUBSET.txt".format(wd = working_dir, post_analysis_dir = post_analysis_dir, post_analysis_out=post_analysis_out), 
        genomes_marker_genes="{wd}/DB/{post_analysis_dir}/all.marker_genes_scores.table".format(wd = working_dir, post_analysis_dir = post_analysis_dir), 
    params:
        tmp_MG=lambda wildcards: "{local_dir}/{post_analysis_out}_marker_genes/".format(local_dir=local_dir, post_analysis_out=post_analysis_out),
        indexprefix="retrieved_MAGs",
    log:
        "{wd}/logs/{omics}/{post_analysis_dir}/{post_analysis_out}_marker_genes.log".format(wd = working_dir, omics = omics, post_analysis_dir = post_analysis_dir, post_analysis_out=post_analysis_out)
    threads: config["BWA_threads"]
    resources:
        mem=config["BWA_memory"]
    conda:
        config["minto_dir"]+"/envs/taxa_env.yml"
    shell: 
        """
        mkdir -p {params.tmp_MG}/
        remote_dir=$(dirname {output.genomes_marker_genes})
        time (Rscript {script_dir}/fetchMGs_fasta_files.R {threads} ${{remote_dir}}/ {post_analysis_out} {normalization} 
        for g in $(cat {input.genomes_list})
            do {fetchMGs_dir}/fetchMGs.pl -outdir {params.tmp_MG}${{g}} -protein_only -threads {threads} -x {fetchMGs_dir}/bin -m extraction ${{remote_dir}}/CD_transl/${{g}}_translated_cds_SUBSET.faa >& {params.tmp_MG}${{g}}_fetchMGs.log
            mv {params.tmp_MG}${{g}}_fetchMGs.log {params.tmp_MG}${{g}}
            mkdir -p ${{remote_dir}}/fetchMGs/${{g}}; \
            rsync -rma {params.tmp_MG}${{g}}/ ${{remote_dir}}/fetchMGs/${{g}}
        done
        flag=True
        for genome in $(cat {input.genomes_list})
            do file={params.tmp_MG}${{genome}}/${{genome}}_translated_cds_SUBSET.all.marker_genes_scores.table
            if [ ${{flag}} == True ]
                then head -n 1 ${{file}} > {params.tmp_MG}all.marker_genes_scores.table
                flag=False
            fi
            awk 'FNR>1' ${{file}} >> {params.tmp_MG}all.marker_genes_scores.table
        done
        rsync {params.tmp_MG}all.marker_genes_scores.table {output.genomes_marker_genes}) &> {log}
        rm -rf {params.tmp_MG}
        """

rule gene_abund_normalization_MG:
    input:
        absolute_counts="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.bed".format(wd = working_dir, omics = omics, post_analysis_out = post_analysis_out, identity = identity),
        genomes_marker_genes="{wd}/DB/{post_analysis_dir}/all.marker_genes_scores.table".format(wd = working_dir, post_analysis_dir = post_analysis_dir), 
    output:
        norm_counts="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.MG.csv"#.format(wd = working_dir, omics = omics, post_analysis_out=post_analysis_out, identity = identity), 
    #params:
    #    tmp_MG="{local_dir}/{post_analysis_out}.MG_marker_genes/"#.format(local_dir=local_dir, post_analysis_out=post_analysis_out),
    log:
        "{wd}/logs/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.MG.log"#.format(wd = working_dir, omics = omics, post_analysis_out=post_analysis_out, identity = identity)
    threads: config["BWA_threads"]
    resources:
        mem=config["BWA_memory"]
    conda:
        config["minto_dir"]+"/envs/taxa_env.yml"
    shell: 
        """
        time (Rscript {script_dir}/profile_MG.R {threads} {resources.mem} {input.absolute_counts} {input.genomes_marker_genes} {output.norm_counts} {omics}) &> {log}
        """

###############################################################################################
# Normalization of read counts by sequence depth and the genes’ length (TPM normalization)
###############################################################################################

rule gene_abund_normalization_TPM:
    input:
        absolute_counts="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.bed",
        #genomes_list="{wd}/DB/{post_analysis_dir}/genomes_list.txt",
    output:
        norm_counts="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.TPM.csv",
    #params:
    #    tmp_norm=lambda wildcards: "{local_dir}/{omics}_{norm}_genes_abundances_normalization/".format(local_dir=local_dir, omics=omics, norm=wildcards.norm),
    log:
        "{wd}/logs/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.TPM.log"
    threads: config["BWA_threads"]
    resources:
        mem=config["BWA_memory"]
    conda:
        config["minto_dir"]+"/envs/taxa_env.yml" #R
    shell:
        """
        time (Rscript {script_dir}/profile_TPM.R {input.absolute_counts} {output.norm_counts} {wildcards.omics}) &> {log}
        """

###############################################################################################
# Merge normalized gene abundance or transcript profiles
###############################################################################################
rule gene_abund_tpm_merge:
    input:
        profile_tpm=expand("{{wd}}/{{omics}}/6-mapping-profiles/BWA_reads-{post_analysis_out}/{sample}/{sample}.p{{identity}}.filtered.profile_TPM.txt.gz", sample=ilmn_samples, post_analysis_out=post_analysis_out), 
    output: 
        profile_tpm_all="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/genes_abundances.p{identity}.TPM.csv"
    params:
        tmp_tpm_merge=lambda wildcards: "{local_dir}/{omics}_{identity}.gene_abund_tpm_merge/".format(local_dir=local_dir, omics=omics, identity=identity),
        profile_tpm_list=lambda wildcards, input: ",".join(input.profile_tpm),
    log:
        "{wd}/logs/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/gene_abund_merge.p{identity}.TPM_log"
    threads: config["BWA_threads"]
    resources:
        mem=config["BWA_memory"]
    conda:
        config["minto_dir"]+"/envs/MIntO_base.yml" #config["conda_env_yml"] # base env
    shell:
        """ mkdir -p {params.tmp_tpm_merge}
        prefix=$(basename {output.profile_tpm_all})
        time (sh {script_dir}/msamtools_merge_profiles.sh {input.profile_tpm[0]} '{params.profile_tpm_list}' db_genes {params.tmp_tpm_merge} ${{prefix}}
        rsync {params.tmp_tpm_merge}${{prefix}} {output.profile_tpm_all}) &> {log}
        rm -rf {params.tmp_tpm_merge}"""

###############################################################################################
# Merge map stats files
## Mappability rate
## Mappability stats
## Multimapping read count
###############################################################################################
rule gene_abund_profiling_merge:
    input: 
        map_profile=expand("{{wd}}/{{omics}}/6-mapping-profiles/BWA_reads-{{post_analysis_out}}/{sample}/{sample}.p{{identity}}.filtered.profile.abund.all.txt.gz", sample=ilmn_samples),
    output: 
        map_profile_all="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.txt",
        maprate="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.maprate.txt",
        mapstats="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.mapstats.txt",
        multimap="{wd}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.multimap.txt"
    params:
        tmp_prof_merge=lambda wildcards: "{local_dir}/{omics}_{identity}.gene_abund_profiling_merge/".format(local_dir=local_dir, omics=omics, identity=identity),
        map_profile_list=lambda wildcards, input: ",".join(input.map_profile),
        prefix="all.p{identity}.filtered.profile.abund.all"
    log:
        "{wd}/logs/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.gene_abund_profiling_merge_log"
    threads: config["BWA_threads"]
    resources:
        mem=config["BWA_memory"]
    conda:
        config["minto_dir"]+"/envs/MIntO_base.yml" # base env
    shell:
        """ mkdir -p {params.tmp_prof_merge}
        time (sh {script_dir}/msamtools_merge_profiles.sh {input.map_profile[0]} '{params.map_profile_list}' genome_abund {params.tmp_prof_merge} {params.prefix}.txt
        sh {script_dir}/msamtools_stats.sh '{params.map_profile_list}' {identity} {params.prefix} {params.tmp_prof_merge}
        rsync {params.tmp_prof_merge}{params.prefix}.maprate.txt {output.maprate}
        rsync {params.tmp_prof_merge}{params.prefix}.mapstats.txt {output.mapstats}
        rsync {params.tmp_prof_merge}{params.prefix}.multimap.txt {output.multimap}
        rsync {params.tmp_prof_merge}{params.prefix}.txt {output.map_profile_all}) &> {log}
        rm -rf {params.tmp_prof_merge}"""

###############################################################################################
# Generate configuration yml file for data integration - gene and function profiles
###############################################################################################
rule config_yml_integration:
    input: 
        map_profile_all=expand("{{wd}}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.txt", omics = omics, post_analysis_out=post_analysis_out, identity=identity),
        maprate=expand("{{wd}}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.maprate.txt", omics = omics, post_analysis_out=post_analysis_out, identity=identity),
        mapstats=expand("{{wd}}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.mapstats.txt", omics = omics, post_analysis_out=post_analysis_out, identity=identity),
        multimap=expand("{{wd}}/{omics}/6-mapping-profiles/BWA_reads-{post_analysis_out}/all.p{identity}.filtered.profile.abund.all.multimap.txt", omics = omics, post_analysis_out=post_analysis_out, identity=identity)
    output: 
        config_file="{wd}/data_integration.yaml"
    params: 
        tmp_integration_yaml=lambda wildcards: "{local_dir}{omics}_config_yml_integration/".format(local_dir=local_dir, omics = omics),
    resources:
        mem=2
    threads: 2
    log: 
        "{wd}/logs/config_yml_integration.log"
    shell: 
        """
        mkdir -p {params.tmp_integration_yaml}
        time (echo "######################
# General settings
######################
PROJECT: {project_id}
working_dir: {wildcards.wd}
omics:
local_dir: {local_dir}
minto_dir: {minto_dir}
METADATA: {metadata}

######################
# Program settings
######################
alignment_identity: {identity}
abundance_normalization: {normalization}
map_reference: {map_reference}

MERGE_threads:
MERGE_memory:

ANNOTATION_file:
ANNOTATION_ids:" > {params.tmp_integration_yaml}data_integration.yaml

rsync {params.tmp_integration_yaml}data_integration.yaml {output.config_file}) >& {log}
rm -rf {params.tmp_integration_yaml}
        """