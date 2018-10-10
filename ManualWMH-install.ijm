// Copy this ManualWMH-install.imj file to Fiji.app/macros/AutoRun 
// per http://imagej.1557.x6.nabble.com/macros-AutoRun-ijm-td5002208.html
run("Install...", "install=[" + getDirectory("imagej") 
   + "/macros/ManualWMH.ijm]"); 
