#######################################################
#
#  Innovus Command Logging File
#  Created on Sat Nov 30 01:02:51 2024
#
#######################################################

#@(#)CDS: Innovus v20.15-s105_1 (64bit) 07/27/2021 14:15 (Linux 2.6.32-431.11.2.el6.x86_64)
#@(#)CDS: NanoRoute 20.15-s105_1 NR210726-1341/20_15-UB (database version 18.20.554) {superthreading v2.14}
#@(#)CDS: AAE 20.15-s020 (64bit) 07/27/2021 (Linux 2.6.32-431.11.2.el6.x86_64)
#@(#)CDS: CTE 20.15-s024_1 () Jul 23 2021 04:46:45 ( )
#@(#)CDS: SYNTECH 20.15-s012_1 () Jul 12 2021 23:29:38 ( )
#@(#)CDS: CPE v20.15-s071
#@(#)CDS: IQuantus/TQuantus 20.1.1-s460 (64bit) Fri Mar 5 18:46:16 PST 2021 (Linux 2.6.32-431.11.2.el6.x86_64)

##################################
# first time check report
##################################
# timeDesign -postCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports
# timeDesign -postCTS -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports


##################################
# Opt for setup time
##################################
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -postCTS
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -postCTS
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -postCTS

# ##################################
# # Opt for hold time
# ##################################
# setOptMode -fixCap true -fixTran true -fixFanoutLoad true
# optDesign -postCTS -hold
# setOptMode -fixCap true -fixTran true -fixFanoutLoad true
# optDesign -postCTS -hold
# setOptMode -fixCap true -fixTran true -fixFanoutLoad true
# optDesign -postCTS -hold


timeDesign -postCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports
timeDesign -postCTS -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports
saveDesign CHIP_postCTS.inn
