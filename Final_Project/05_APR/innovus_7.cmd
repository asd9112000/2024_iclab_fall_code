#====================================================================
#  Connect Core Power Pin (for SRAM's block pin, if you do not have SRAM then you can skip this step)
#====================================================================
setSrouteMode -viaConnectToShape { ring blockring }
sroute -connect { blockPin } -layerChangeRange { metal1(1) metal6(6) } -blockPinTarget { nearestTarget } -allowJogging 1 -crossoverViaLayerRange { metal1(1) metal6(6) } -allowLayerChange 1 -blockPin useLef -targetViaLayerRange { metal1(1) metal6(6) }

