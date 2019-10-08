var _anomFunkMap={},_anomFunkMapNextId=0;function anomToNameFunk(){var a="f"+_anomFunkMapNextId++;_anomFunkMap[a]=function(){_anomFunkMap[a].apply(this,arguments);_anomFunkMap[a]=null;delete _anomFunkMap[a]};return"_anomFunkMap."+a}function GetFunctionName(a){if(a){var b=a.toString().match(/^\s*function\s+([^\s\(]+)/);return b?b[1]:anomToNameFunk(a)}else return null}if(typeof DeviceInfo!="object")DeviceInfo={};PhoneGap={queue:{ready:true,commands:[],timer:null},_constructors:[]};
PhoneGap.available=DeviceInfo.uuid!=undefined;PhoneGap.addConstructor=function(a){var b=document.readyState;(b=="loaded"||b=="complete")&&DeviceInfo.uuid!=null?a():PhoneGap._constructors.push(a)};
(function(){var a=setInterval(function(){var b=document.readyState;if((b=="loaded"||b=="complete")&&DeviceInfo.uuid!=null){for(clearInterval(a);PhoneGap._constructors.length>0;){b=PhoneGap._constructors.shift();try{b()}catch(c){typeof debug.log=="function"?debug.log("Failed to run constructor: "+debug.processMessage(c)):alert("Failed to run constructor: "+c.message)}}b=document.createEvent("Events");b.initEvent("deviceready");document.dispatchEvent(b)}},1)})();
PhoneGap.exec=function(){PhoneGap.queue.commands.push(arguments);if(PhoneGap.queue.timer==null)PhoneGap.queue.timer=setInterval(PhoneGap.run_command,10)};
PhoneGap.run_command=function(){if(PhoneGap.available&&PhoneGap.queue.ready){PhoneGap.queue.ready=false;var a=PhoneGap.queue.commands.shift();if(PhoneGap.queue.commands.length==0){clearInterval(PhoneGap.queue.timer);PhoneGap.queue.timer=null}for(var b=[],c=null,d=1;d<a.length;d++){var e=a[d];if(e==undefined||e==null)e="";if(typeof e=="object")c=e;else b.push(encodeURIComponent(e))}a="gap://"+a[0]+"/"+b.join("/");if(c!=null){b=[];for(var f in c)typeof f=="string"&&b.push(encodeURIComponent(f)+"="+
encodeURIComponent(c[f]));if(b.length>0)a+="?"+b.join("&")}document.location=a}};function Acceleration(a,b,c){this.x=a;this.y=b;this.z=c;this.timestamp=(new Date).getTime()}function AccelerationOptions(){this.timeout=1E4}function Accelerometer(){this.lastAcceleration=new Acceleration(0,0,0)}Accelerometer.prototype.getCurrentAcceleration=function(a){typeof a=="function"&&a(this.lastAcceleration)};Accelerometer.prototype._onAccelUpdate=function(a,b,c){this.lastAcceleration=new Acceleration(a,b,c)};
Accelerometer.prototype.watchAcceleration=function(a,b,c){var d=c!=undefined&&c.frequency!=undefined?c.frequency:1E4;PhoneGap.exec("Accelerometer.start",c);return setInterval(function(){navigator.accelerometer.getCurrentAcceleration(a,b,c)},d)};Accelerometer.prototype.clearWatch=function(a){PhoneGap.exec("Accelerometer.stop");clearInterval(a)};PhoneGap.addConstructor(function(){if(typeof navigator.accelerometer=="undefined")navigator.accelerometer=new Accelerometer});function Camera(){}
Camera.prototype.getPicture=function(a,b,c){PhoneGap.exec("Camera.getPicture",GetFunctionName(a),GetFunctionName(b),c)};PhoneGap.addConstructor(function(){if(typeof navigator.camera=="undefined")navigator.camera=new Camera});function Contact(){this.name=this.lastName=this.firstName="";this.phones={};this.emails={};this.address=""}Contact.prototype.displayName=function(){return this.name};function ContactManager(){this.contacts=[];this.timestamp=(new Date).getTime()}
ContactManager.prototype.getAllContacts=function(a,b,c){PhoneGap.exec("Contacts.allContacts",GetFunctionName(a),c)};ContactManager.prototype.newContact=function(a,b,c){c||(c={});c.successCallback=GetFunctionName(b);PhoneGap.exec("Contacts.newContact",a.firstName,a.lastName,a.phoneNumber,c)};ContactManager.prototype.chooseContact=function(a,b){PhoneGap.exec("Contacts.chooseContact",GetFunctionName(a),b)};
ContactManager.prototype.displayContact=function(a,b,c){PhoneGap.exec("Contacts.displayContact",a,GetFunctionName(b),c)};ContactManager.prototype.removeContact=function(a,b,c){PhoneGap.exec("Contacts.removeContact",a,GetFunctionName(b),c)};ContactManager.prototype.contactsCount=function(a){PhoneGap.exec("Contacts.contactsCount",GetFunctionName(a))};PhoneGap.addConstructor(function(){if(typeof navigator.contacts=="undefined")navigator.contacts=new ContactManager});function DebugConsole(){}
DebugConsole.prototype.processMessage=function(a){if(typeof a!="object")return a;else{var b=function(c){var d="";for(var e in c)try{var f=d,g;if(typeof c[e]=="object"){var h=e+":\n",i;i=b(c[e]).replace(/^/mg,"    ");g=h+i+"\n"}else g=e+" = "+String(c[e]).replace(/^/mg,"    ").replace(/^    /,"")+"\n";d=f+g}catch(j){d+=e+" = EXCEPTION: "+j.message+"\n"}return d};return"Object:\n"+b(a)}};
DebugConsole.prototype.log=function(a){PhoneGap.available?PhoneGap.exec("DebugConsole.log",this.processMessage(a),{logLevel:"INFO"}):console.log(a)};DebugConsole.prototype.warn=function(a){PhoneGap.available?PhoneGap.exec("DebugConsole.log",this.processMessage(a),{logLevel:"WARN"}):console.error(a)};DebugConsole.prototype.error=function(a){PhoneGap.available?PhoneGap.exec("DebugConsole.log",this.processMessage(a),{logLevel:"ERROR"}):console.error(a)};
PhoneGap.addConstructor(function(){window.debug=new DebugConsole});function Device(){this.uuid=this.gap=this.name=this.version=this.platform=null;try{this.platform=DeviceInfo.platform;this.version=DeviceInfo.version;this.name=DeviceInfo.name;this.gap=DeviceInfo.gap;this.uuid=DeviceInfo.uuid}catch(a){}this.available=PhoneGap.available=this.uuid!=null}PhoneGap.addConstructor(function(){navigator.device=window.device=new Device});
PhoneGap.addConstructor(function(){if(typeof navigator.fileMgr=="undefined")navigator.fileMgr=new FileMgr});function FileMgr(){this.fileWriters={};this.fileReaders={};this.docsFolderPath="../../Documents";this.tempFolderPath="../../tmp";this.freeDiskSpace=-1;this.getFileBasePaths();this.getFreeDiskSpace()}FileMgr.prototype._setPaths=function(a,b){this.docsFolderPath=a;this.tempFolderPath=b};FileMgr.prototype._setFreeDiskSpace=function(a){this.freeDiskSpace=a};
FileMgr.prototype.addFileWriter=function(a,b){this.fileWriters[a]=b};FileMgr.prototype.removeFileWriter=function(a){this.fileWriters[a]=null};FileMgr.prototype.addFileReader=function(a,b){this.fileReaders[a]=b};FileMgr.prototype.removeFileReader=function(a){this.fileReaders[a]=null};FileMgr.prototype.reader_onloadstart=function(a,b){this.fileReaders[a].onloadstart(b)};FileMgr.prototype.reader_onprogress=function(a,b){this.fileReaders[a].onprogress(b)};
FileMgr.prototype.reader_onload=function(a,b){this.fileReaders[a].result=unescape(b);this.fileReaders[a].onload(this.fileReaders[a].result)};FileMgr.prototype.reader_onerror=function(a,b){this.fileReaders[a].result=b;this.fileReaders[a].onerror(b)};FileMgr.prototype.reader_onloadend=function(a,b){this.fileReaders[a].onloadend(b)};FileMgr.prototype.writer_onerror=function(a,b){this.fileWriters[a].onerror(b)};FileMgr.prototype.writer_oncomplete=function(a,b){this.fileWriters[a].oncomplete(b)};
FileMgr.prototype.getFileBasePaths=function(){PhoneGap.exec("File.getFileBasePaths")};FileMgr.prototype.testFileExists=function(a){PhoneGap.exec("File.testFileExists",a)};FileMgr.prototype.testDirectoryExists=function(a,b,c){this.successCallback=b;this.errorCallback=c;PhoneGap.exec("File.testDirectoryExists",a)};FileMgr.prototype.createDirectory=function(a,b,c){this.successCallback=b;this.errorCallback=c;PhoneGap.exec("File.createDirectory",a)};
FileMgr.prototype.deleteDirectory=function(a,b,c){this.successCallback=b;this.errorCallback=c;PhoneGap.exec("File.deleteDirectory",a)};FileMgr.prototype.deleteFile=function(a,b,c){this.successCallback=b;this.errorCallback=c;PhoneGap.exec("File.deleteFile",a)};FileMgr.prototype.getFreeDiskSpace=function(a,b){if(this.freeDiskSpace>0)return this.freeDiskSpace;else{this.successCallback=a;this.errorCallback=b;PhoneGap.exec("File.getFreeDiskSpace")}};File.prototype.hasRead=function(){};
function FileReader(){this.fileName="";this.onloadend=this.onerror=this.onload=this.onprogress=this.onloadstart=this.result=null}FileReader.prototype.abort=function(){};FileReader.prototype.readAsText=function(a){this.fileName&&this.fileName.length>0&&navigator.fileMgr.removeFileReader(this.fileName,this);this.fileName=a;navigator.fileMgr.addFileReader(this.fileName,this);PhoneGap.exec("File.readFile",this.fileName)};
function FileWriter(){this.fileName="";this.result=null;this.readyState=0;this.oncomplete=this.onerror=this.result=null}FileWriter.prototype.writeAsText=function(a,b,c){this.fileName&&this.fileName.length>0&&navigator.fileMgr.removeFileWriter(this.fileName,this);this.fileName=a;if(c!=true)c=false;navigator.fileMgr.addFileWriter(a,this);this.readyState=0;this.result=null;PhoneGap.exec("File.write",a,b,c)};function PositionError(){this.code=0;this.message=""}PositionError.PERMISSION_DENIED=1;
PositionError.POSITION_UNAVAILABLE=2;PositionError.TIMEOUT=3;function Geolocation(){this.lastError=this.lastPosition=null}
Geolocation.prototype.getCurrentPosition=function(a,b,c){if(this.lastError!=null){typeof b=="function"&&b.call(null,this.lastError);this.stop()}else{this.start(c);var d=500;if(typeof c=="object"&&c.interval)d=c.interval;if(typeof a!="function")a=function(){};if(typeof b!="function")b=function(){};var e=this,f=0,g=setInterval(function(){f+=d;if(typeof e.lastPosition=="object"&&e.lastPosition.timestamp>0){clearInterval(g);a(e.lastPosition)}else if(f>2E4){clearInterval(g);b("Error Timeout")}else if(e.lastError!=
null){clearInterval(g);b(e.lastError)}},d)}};Geolocation.prototype.watchPosition=function(a,b,c){this.getCurrentPosition(a,b,c);var d=1E4;if(typeof c=="object"&&c.frequency)d=c.frequency;var e=this;return setInterval(function(){e.getCurrentPosition(a,b,c)},d)};Geolocation.prototype.clearWatch=function(a){clearInterval(a)};Geolocation.prototype.setLocation=function(a){this.lastError=null;this.lastPosition=a};Geolocation.prototype.setError=function(a){this.lastError=a};
Geolocation.prototype.start=function(a){PhoneGap.exec("Location.startLocation",a)};Geolocation.prototype.stop=function(){PhoneGap.exec("Location.stopLocation")};function __proxyObj(a,b,c){var d=function(f,g,h){f[h]=function(){return g[h].apply(g,arguments)}};for(var e in c)d(a,b,c[e])}
PhoneGap.addConstructor(function(){if(typeof navigator._geo=="undefined"){navigator._geo=new Geolocation;__proxyObj(navigator.geolocation,navigator._geo,["setLocation","getCurrentPosition","watchPosition","clearWatch","setError","start","stop"])}});function Compass(){this.lastError=this.lastHeading=null;this.callbacks={onHeadingChanged:[],onError:[]}}Compass.prototype.getCurrentHeading=function(a,b,c){if(this.lastHeading==null)this.start(c);else typeof a=="function"&&a(this.lastHeading)};
Compass.prototype.watchHeading=function(a,b,c){this.getCurrentHeading(a,b,c);var d=100;if(typeof c=="object"&&c.frequency)d=c.frequency;var e=this;return setInterval(function(){e.getCurrentHeading(a,b,c)},d)};Compass.prototype.clearWatch=function(a){clearInterval(a)};Compass.prototype.setHeading=function(a){this.lastHeading=a;for(var b=0;b<this.callbacks.onHeadingChanged.length;b++)this.callbacks.onHeadingChanged.shift()(a)};Compass.prototype.setError=function(a){this.lastError=a;for(var b=0;b<this.callbacks.onError.length;b++)this.callbacks.onError.shift()(a)};
Compass.prototype.start=function(a){PhoneGap.exec("Location.startHeading",a)};Compass.prototype.stop=function(){PhoneGap.exec("Location.stopHeading")};PhoneGap.addConstructor(function(){if(typeof navigator.compass=="undefined")navigator.compass=new Compass});function Map(){}Map.prototype.show=function(){};PhoneGap.addConstructor(function(){if(typeof navigator.map=="undefined")navigator.map=new Map});
function Media(a,b,c){a||(a="documents://"+String((new Date).getTime()).replace(/\D/gi,""));this.src=a;this.successCallback=b;this.errorCallback=c;this.src!=null&&PhoneGap.exec("Sound.prepare",this.src,this.successCallback,this.errorCallback)}Media.prototype.play=function(a){this.src!=null&&PhoneGap.exec("Sound.play",this.src,a)};Media.prototype.pause=function(){this.src!=null&&PhoneGap.exec("Sound.pause",this.src)};Media.prototype.stop=function(){this.src!=null&&PhoneGap.exec("Sound.stop",this.src)};
Media.prototype.startAudioRecord=function(a){this.src!=null&&PhoneGap.exec("Sound.startAudioRecord",this.src,a)};Media.prototype.stopAudioRecord=function(){this.src!=null&&PhoneGap.exec("Sound.stopAudioRecord",this.src)};function MediaError(){this.code=null;this.message=""}MediaError.MEDIA_ERR_ABORTED=1;MediaError.MEDIA_ERR_NETWORK=2;MediaError.MEDIA_ERR_DECODE=3;MediaError.MEDIA_ERR_NONE_SUPPORTED=4;function Notification(){}Notification.prototype.blink=function(){};
Notification.prototype.vibrate=function(){PhoneGap.exec("Notification.vibrate")};Notification.prototype.beep=function(){(new Media("beep.wav")).play()};Notification.prototype.alert=function(a,b,c){if(PhoneGap.available){var d={};if(b)d.title=b;if(c)d.buttonLabel=c;PhoneGap.exec("Notification.alert",a,d);return this._alertDelegate={}}else return alert(a)};Notification.prototype.confirm=function(a,b,c){return PhoneGap.available?this.alert(a,b,c?c:"OK,Cancel"):confirm(a)};
Notification.prototype._alertCallback=function(a,b){this._alertDelegate.onAlertDismissed(a,b)};Notification.prototype.activityStart=function(){PhoneGap.exec("Notification.activityStart")};Notification.prototype.activityStop=function(){PhoneGap.exec("Notification.activityStop")};Notification.prototype.loadingStart=function(a){PhoneGap.exec("Notification.loadingStart",a)};Notification.prototype.loadingStop=function(){PhoneGap.exec("Notification.loadingStop")};
PhoneGap.addConstructor(function(){if(typeof navigator.notification=="undefined")navigator.notification=new Notification});function Orientation(){this.currentOrientation=null}Orientation.prototype.setOrientation=function(a){Orientation.currentOrientation=a;var b=document.createEvent("Events");b.initEvent("orientationChanged","false","false");b.orientation=a;document.dispatchEvent(b)};Orientation.prototype.getCurrentOrientation=function(){};
Orientation.prototype.watchOrientation=function(a,b){this.getCurrentPosition(a,b);return setInterval(function(){navigator.orientation.getCurrentOrientation(a,b)},1E4)};Orientation.prototype.clearWatch=function(a){clearInterval(a)};PhoneGap.addConstructor(function(){if(typeof navigator.orientation=="undefined")navigator.orientation=new Orientation});function Position(a){this.coords=a;this.timestamp=(new Date).getTime()}
function Coordinates(a,b,c,d,e,f){this.latitude=a;this.longitude=b;this.accuracy=d;this.altitude=c;this.heading=e;this.speed=f}function PositionOptions(){this.enableHighAccuracy=true;this.timeout=1E4}function PositionError(){this.code=null;this.message=""}PositionError.UNKNOWN_ERROR=0;PositionError.PERMISSION_DENIED=1;PositionError.POSITION_UNAVAILABLE=2;PositionError.TIMEOUT=3;function Sms(){}Sms.prototype.send=function(){};
PhoneGap.addConstructor(function(){if(typeof navigator.sms=="undefined")navigator.sms=new Sms});function Telephony(){}Telephony.prototype.call=function(){};PhoneGap.addConstructor(function(){if(typeof navigator.telephony=="undefined")navigator.telephony=new Telephony});function UIControls(){this.tabBarTag=0;this.tabBarCallbacks={}}UIControls.prototype.createTabBar=function(){PhoneGap.exec("UIControls.createTabBar")};
UIControls.prototype.showTabBar=function(a){a||(a={});PhoneGap.exec("UIControls.showTabBar",a)};UIControls.prototype.hideTabBar=function(a){if(a==undefined||a==null)a=true;PhoneGap.exec("UIControls.hideTabBar",{animate:a})};UIControls.prototype.createTabBarItem=function(a,b,c,d){var e=this.tabBarTag++;if(d&&"onSelect"in d&&typeof d.onSelect=="function"){this.tabBarCallbacks[e]=d.onSelect;delete d.onSelect}PhoneGap.exec("UIControls.createTabBarItem",a,b,c,e,d)};
UIControls.prototype.updateTabBarItem=function(a,b){b||(b={});PhoneGap.exec("UIControls.updateTabBarItem",a,b)};UIControls.prototype.showTabBarItems=function(){for(var a=["UIControls.showTabBarItems"],b=0;b<arguments.length;b++)a.push(arguments[b]);PhoneGap.exec.apply(this,a)};UIControls.prototype.selectTabBarItem=function(a){PhoneGap.exec("UIControls.selectTabBarItem",a)};UIControls.prototype.tabBarItemSelected=function(a){typeof this.tabBarCallbacks[a]=="function"&&this.tabBarCallbacks[a]()};
UIControls.prototype.createToolBar=function(){PhoneGap.exec("UIControls.createToolBar")};UIControls.prototype.setToolBarTitle=function(a){PhoneGap.exec("UIControls.setToolBarTitle",a)};PhoneGap.addConstructor(function(){window.uicontrols=new UIControls});function NetworkStatus(){this.code=null;this.message=""}NetworkStatus.NOT_REACHABLE=0;NetworkStatus.REACHABLE_VIA_CARRIER_DATA_NETWORK=1;NetworkStatus.REACHABLE_VIA_WIFI_NETWORK=2;function Network(){this.lastReachability=null}
Network.prototype.isReachable=function(a,b,c){PhoneGap.exec("Network.isReachable",a,GetFunctionName(b),c)};Network.prototype.updateReachability=function(a){this.lastReachability=a};PhoneGap.addConstructor(function(){if(typeof navigator.network=="undefined")navigator.network=new Network});