import os
import time

from cyvcf2 import VCF


OUTFILE = 'output/genotype.csv'


# When the strict_gt flag is enabled, cyvcf2 will treat any genotype containing a missing allele (containing a ‘.’) 
# as an UNKNOWN genotype; otherwise, genotypes like 0/., ./0, 1/., or ./1 will be classified as heterozygous (“HET”).
# 0=HOM_REF, 1=HET, 2=HOM_ALT, 3=UNKNOWN

if __name__ == '__main__':

    start_time = time.perf_counter()

    # remove GT csv file if already exists
    if os.path.exists(OUTFILE):
        os.remove(OUTFILE)

    # read VCF file 
    vcf = VCF(
        'data/Training_Data/5_Genotype_Data_All_Years.vcf',
        gts012=True,
        strict_gt=True
    )

    # write GT arrays to csv
    with open(OUTFILE, 'a') as csvfile:
        header = ','.join(list(vcf.samples)) + '\n'
        csvfile.write(header)
        for variant in vcf:
            txt = ','.join([str(x) for x in variant.gt_types.astype('int64')]) + '\n'
            csvfile.write(txt)

    end_time = time.perf_counter()
    total_time = (end_time - start_time) / 60
    print('Total minutes:', round(total_time, 2))
