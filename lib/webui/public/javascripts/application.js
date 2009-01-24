$(window).addEvent("domready", function() {
	
	/* add the external stylesheet containing all of
	 * the backend stuff, to keep it out of master.css */
	new Element("link", {
		"rel": "stylesheet",
		"type": "text/css",
		"media": "screen",
		"href": "/stylesheets/backend.css"
	}).inject(document.head);
	
	var nest = new Element("div", {
		"id": "backend",
	}).inject(document.body);
	
	var trigger = new Element("div", {
		"title": "Connect to HTTP Backend",
		"class": "trigger",
		"events": {
			"click": function() {
				
				/* keep a backend session cookied, so
				 * we load the same content in the
				 * iframe each time between loads */
				var c = new Cookie("backend-session-id", { "path": "/" });
				var session = c.read();
				
				/* start a new session (six digits)
				 * if one isn't already started */
				if (session == null) {
					session = $random(111111, 999999);
					c.write(session);
				}
				
				/* load the http backend in an
				 * iframe like google chat */
				new Element("iframe", {
					"src": "http://localhost:1270/" + session
				}).inject(nest);
			}
		}
	}).inject(nest);
});
