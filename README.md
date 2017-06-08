# GPUHeatMonitor
Application that monitors and charts NVidia Graphics cards temperature.

While working on some long running kernels I wanted to keep track of the GPU's temperature and ran the monitor app that came on the manufacturer supplied installation disks. The problem with the monitoring apps that I have is that they are quite large and take up a lot of screen space and for some unknown reason they crash / stop working when viewed over VNC (or similar) remote control app.  Now as I mostly use my CUDA machines over the network this is not a good situation.

So decided to write my own. It still needs config and possibly some remote reporting over the network functionality. Currently it can display the temperature from two GPU's and updates every 500ms. When minimized it sits in the system tray and updates its tooltip with the reported temperatures. The current .exe is +-146k (mostly the skin) and doesn't require any installer.
