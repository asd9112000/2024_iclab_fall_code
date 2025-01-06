#====================================================================
# Connect/Define Global Net
#====================================================================
clearGlobalNets
globalNetConnect VCC -type pgpin -pin VCC -instanceBasename *
globalNetConnect VCC -type net -net VCC
globalNetConnect VCC -type tiehi -pin VCC -instanceBasename *
globalNetConnect GND -type pgpin -pin GND -instanceBasename *
globalNetConnect GND -type net -net GND
globalNetConnect GND -type tielo -pin GND -instanceBasename *

