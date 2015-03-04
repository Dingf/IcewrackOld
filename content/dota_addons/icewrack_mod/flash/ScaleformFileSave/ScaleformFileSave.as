package
{
	import flash.display.MovieClip;
	import flash.net.Socket;
	
	public class ScaleformFileSave extends MovieClip
	{
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		public function ScaleformFileSave()
		{
			// constructor code
		}
		
		public function onLoaded() : void
		{
		}
		
		public function SendData(args:Object) : void
		{
			
		}
		
		public function statCollectSend(args:Object) {
85	            // Tell the client
86				trace("##STATS Sending payload:");
87				trace(json);
88	
89	            // Create the socket
90				sock = new Socket();
91				sock.timeout = 10000; //10 seconds is fair..
92				// Setup socket event handlers
93				sock.addEventListener(Event.CONNECT, socketConnect);
94	
95				try {
96					// Connect
97					sock.connect(SERVER_ADDRESS, SERVER_PORT);
98				} catch (e:Error) {
99					// Oh shit, there was an error
100					trace("##STATS Failed to connect!");
101	
102					// Return failure
103					return false;
104				}
105			}
			
			
			
24	            // Tell the user what is going on
25	            trace("##Loading StatsCollection...");
26	
27	            // Reset our json
28	            json = '';
29	
30	            // Load KV
31	            var settings = globals.GameInterface.LoadKVFile('scripts/stat_collection.kv');
32	
33	            // Load the live setting
34	            var live:Boolean = (settings.live == "1");
35	
36	            // Load the settings for the given mode
37	            if(live) {
38	                // Load live settings
39	                SERVER_ADDRESS = settings.SERVER_ADDRESS_LIVE;
40	                SERVER_PORT = parseInt(settings.SERVER_PORT_LIVE);
41	
42	                // Tell the user it's live mode
43	                trace("StatsCollection is set to LIVE mode.");
44	            } else {
45	                // Load live settings
46	                SERVER_ADDRESS = settings.SERVER_ADDRESS_TEST;
47	                SERVER_PORT = parseInt(settings.SERVER_PORT_TEST);
48	
49	                // Tell the user it's test mode
50	                trace("StatsCollection is set to TEST mode.");
51	            }
52	
53	            // Log the server
54	            trace("Server was set to "+SERVER_ADDRESS+":"+SERVER_PORT);
55	
56	            // Hook the stat collection event
57	            gameAPI.SubscribeToGameEvent("stat_collection_part", this.statCollectPart);
58	            gameAPI.SubscribeToGameEvent("stat_collection_send", this.statCollectSend);
59	        }
	}
	
}

package  {
2	
3		import flash.display.MovieClip;
4		import flash.net.Socket;
5	    import flash.utils.ByteArray;
6	    import flash.events.Event;
7	    import flash.events.ProgressEvent;
8	    import flash.events.IOErrorEvent;
9	    import flash.utils.Timer;
10	    import flash.events.TimerEvent;
11	
12	    public class StatsCollection extends MovieClip {
13	        public var gameAPI:Object;
14	        public var globals:Object;
15	        public var elementName:String;
16	
17			var sock:Socket;
18			var json:String;
19	
20			var SERVER_ADDRESS:String = "176.31.182.87";
21			var SERVER_PORT:Number = 4444;
22	
23	        public function onLoaded() : void {
24	            // Tell the user what is going on
25	            trace("##Loading StatsCollection...");
26	
27	            // Reset our json
28	            json = '';
29	
30	            // Load KV
31	            var settings = globals.GameInterface.LoadKVFile('scripts/stat_collection.kv');
32	
33	            // Load the live setting
34	            var live:Boolean = (settings.live == "1");
35	
36	            // Load the settings for the given mode
37	            if(live) {
38	                // Load live settings
39	                SERVER_ADDRESS = settings.SERVER_ADDRESS_LIVE;
40	                SERVER_PORT = parseInt(settings.SERVER_PORT_LIVE);
41	
42	                // Tell the user it's live mode
43	                trace("StatsCollection is set to LIVE mode.");
44	            } else {
45	                // Load live settings
46	                SERVER_ADDRESS = settings.SERVER_ADDRESS_TEST;
47	                SERVER_PORT = parseInt(settings.SERVER_PORT_TEST);
48	
49	                // Tell the user it's test mode
50	                trace("StatsCollection is set to TEST mode.");
51	            }
52	
53	            // Log the server
54	            trace("Server was set to "+SERVER_ADDRESS+":"+SERVER_PORT);
55	
56	            // Hook the stat collection event
57	            gameAPI.SubscribeToGameEvent("stat_collection_part", this.statCollectPart);
58	            gameAPI.SubscribeToGameEvent("stat_collection_send", this.statCollectSend);
59	        }
60			public function socketConnect(e:Event) {
61				// We have connected successfully!
62	            trace('Connected to the server!');
63	
64	            // Hook the data connection
65	            //sock.addEventListener(ProgressEvent.SOCKET_DATA, socketData);
66				var buff:ByteArray = new ByteArray();
67				writeString(buff, json + '\r\n');
68				sock.writeBytes(buff, 0, buff.length);
69	            sock.flush();
70			}
71			private static function writeString(buff:ByteArray, write:String){
72				trace("Message: "+write);
73				trace("Length: "+write.length);
74	            buff.writeUTFBytes(write);
75	        }
76	        public function statCollectPart(args:Object) {
77	            // Tell the client
78	            trace("##STATS Part of that stat data recieved:");
79	            trace(args.data);
80	
81	            // Store the extra data
82	            json = json + args.data;
83	        }
84			public function statCollectSend(args:Object) {
85	            // Tell the client
86				trace("##STATS Sending payload:");
87				trace(json);
88	
89	            // Create the socket
90				sock = new Socket();
91				sock.timeout = 10000; //10 seconds is fair..
92				// Setup socket event handlers
93				sock.addEventListener(Event.CONNECT, socketConnect);
94	
95				try {
96					// Connect
97					sock.connect(SERVER_ADDRESS, SERVER_PORT);
98				} catch (e:Error) {
99					// Oh shit, there was an error
100					trace("##STATS Failed to connect!");
101	
102					// Return failure
103					return false;
104				}
105			}
106	    }
107	}
