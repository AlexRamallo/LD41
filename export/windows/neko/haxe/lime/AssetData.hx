package lime;


import lime.utils.Assets;


class AssetData {

	private static var initialized:Bool = false;
	
	public static var library = new #if haxe3 Map <String, #else Hash <#end LibraryType> ();
	public static var path = new #if haxe3 Map <String, #else Hash <#end String> ();
	public static var type = new #if haxe3 Map <String, #else Hash <#end AssetType> ();	
	
	public static function initialize():Void {
		
		if (!initialized) {
			
			path.set ("assets/data/data-goes-here.txt", "assets/data/data-goes-here.txt");
			type.set ("assets/data/data-goes-here.txt", Reflect.field (AssetType, "text".toUpperCase ()));
			path.set ("assets/images/background.png", "assets/images/background.png");
			type.set ("assets/images/background.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/ball.png", "assets/images/ball.png");
			type.set ("assets/images/ball.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/bomb.png", "assets/images/bomb.png");
			type.set ("assets/images/bomb.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/bullet.png", "assets/images/bullet.png");
			type.set ("assets/images/bullet.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/crosshair.png", "assets/images/crosshair.png");
			type.set ("assets/images/crosshair.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/enemy.png", "assets/images/enemy.png");
			type.set ("assets/images/enemy.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/gameover.png", "assets/images/gameover.png");
			type.set ("assets/images/gameover.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/menu_bg.png", "assets/images/menu_bg.png");
			type.set ("assets/images/menu_bg.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/menu_bg_instruct.png", "assets/images/menu_bg_instruct.png");
			type.set ("assets/images/menu_bg_instruct.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/menu_bg_instruct2.png", "assets/images/menu_bg_instruct2.png");
			type.set ("assets/images/menu_bg_instruct2.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/menu_bg_instruct3.png", "assets/images/menu_bg_instruct3.png");
			type.set ("assets/images/menu_bg_instruct3.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/shards.png", "assets/images/shards.png");
			type.set ("assets/images/shards.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/upgrades.png", "assets/images/upgrades.png");
			type.set ("assets/images/upgrades.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/xpl.png", "assets/images/xpl.png");
			type.set ("assets/images/xpl.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/images/xpl_sm.png", "assets/images/xpl_sm.png");
			type.set ("assets/images/xpl_sm.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("assets/music/buy.wav", "assets/music/buy.wav");
			type.set ("assets/music/buy.wav", Reflect.field (AssetType, "sound".toUpperCase ()));
			path.set ("assets/music/enemy_die.wav", "assets/music/enemy_die.wav");
			type.set ("assets/music/enemy_die.wav", Reflect.field (AssetType, "sound".toUpperCase ()));
			path.set ("assets/music/explode.wav", "assets/music/explode.wav");
			type.set ("assets/music/explode.wav", Reflect.field (AssetType, "sound".toUpperCase ()));
			path.set ("assets/music/hit.wav", "assets/music/hit.wav");
			type.set ("assets/music/hit.wav", Reflect.field (AssetType, "sound".toUpperCase ()));
			path.set ("assets/music/hit_marble.wav", "assets/music/hit_marble.wav");
			type.set ("assets/music/hit_marble.wav", Reflect.field (AssetType, "sound".toUpperCase ()));
			path.set ("assets/music/hit_marble_2.wav", "assets/music/hit_marble_2.wav");
			type.set ("assets/music/hit_marble_2.wav", Reflect.field (AssetType, "sound".toUpperCase ()));
			path.set ("assets/music/miss.wav", "assets/music/miss.wav");
			type.set ("assets/music/miss.wav", Reflect.field (AssetType, "sound".toUpperCase ()));
			path.set ("assets/music/music-goes-here.txt", "assets/music/music-goes-here.txt");
			type.set ("assets/music/music-goes-here.txt", Reflect.field (AssetType, "text".toUpperCase ()));
			path.set ("assets/sounds/sounds-go-here.txt", "assets/sounds/sounds-go-here.txt");
			type.set ("assets/sounds/sounds-go-here.txt", Reflect.field (AssetType, "text".toUpperCase ()));
			path.set ("flixel/sounds/beep.ogg", "flixel/sounds/beep.ogg");
			type.set ("flixel/sounds/beep.ogg", Reflect.field (AssetType, "sound".toUpperCase ()));
			path.set ("flixel/sounds/flixel.ogg", "flixel/sounds/flixel.ogg");
			type.set ("flixel/sounds/flixel.ogg", Reflect.field (AssetType, "sound".toUpperCase ()));
			path.set ("flixel/fonts/nokiafc22.ttf", "flixel/fonts/nokiafc22.ttf");
			type.set ("flixel/fonts/nokiafc22.ttf", Reflect.field (AssetType, "font".toUpperCase ()));
			path.set ("flixel/fonts/monsterrat.ttf", "flixel/fonts/monsterrat.ttf");
			type.set ("flixel/fonts/monsterrat.ttf", Reflect.field (AssetType, "font".toUpperCase ()));
			path.set ("flixel/images/ui/button.png", "flixel/images/ui/button.png");
			type.set ("flixel/images/ui/button.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("flixel/images/logo/default.png", "flixel/images/logo/default.png");
			type.set ("flixel/images/logo/default.png", Reflect.field (AssetType, "image".toUpperCase ()));
			
			
			initialized = true;
			
		} //!initialized
		
	} //initialize
	
	
} //AssetData
