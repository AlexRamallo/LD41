package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.FlxObject;

interface Target{
	public function onShot():Bool;
}
class Help{
	public static function clamp(val:Float, min:Float, max:Float):Float{
		if (val < min) val = min;
		if (val > max) val = max;
		return val;
	}
	public static function degtorad(deg:Float):Float{
		return deg * Math.PI / 180.0;
	}
	public static function radtodeg(rad:Float):Float{
		return rad / Math.PI * 180.0;
	}
}

class BulletManager{
	public var shotxpl:Array<Explosion> = [];
	public var bullets:Array<Bullet> = [];
	public var enemies:Array<Enemy> = [];
	public var bombs:Array<Bomb> = [];
	public function new(ct, ct_bomb, ct_enemy, ct_xpl, B){
		for (i in 0...ct_enemy){
			var e = new Enemy(0, 0, B, this);
			enemies.push(e);
			FlxG.state.add(e);
		}
		
		for (i in 0...ct){
			var bb = new Bullet(0, 0, B);
			bullets.push(bb);
			FlxG.state.add(bb);
		}
		
		for (i in 0...ct_bomb){
			var bb = new Bomb(0, 0, this);
			bombs.push(bb);
			FlxG.state.add(bb);
		}
		
		for (i in 0...ct_xpl){
			var xpl = new Explosion(0, 0);
			shotxpl.push(xpl);
		}
	}
	public function add_xpl_to_scene(){
		for (xpl in shotxpl)
			FlxG.state.add(xpl);
	}
	public function request(count:Int):Array<Bullet>{
		var ret = [];
		for (b in bullets){
			if (ret.length >= count) break;
			if (!b.visible)
				ret.push(b);
		}
		return ret;
	}
	
	public function request_bomb():Bomb{
		for (b in bombs){
			if (!b.visible)
				return b;
		}
		return null;
	}
	
	public function request_xpl(count:Int):Array<Explosion>{
		var ret = [];
		for (xpl in shotxpl){
			if (ret.length >= count) break;
			if (xpl.animation.finished)
				ret.push(xpl);
		}
		return ret;
	}
	
	public function request_enemy():Enemy{
		for (e in enemies){
			if (!e.visible)
				return e;
		}
		return null;
	}
}

class Enemy extends FlxSprite implements Target{
	public var ball:Ball = null;
	public var state:Int = 0;
	var bmgr:BulletManager = null;
	public static var maxhp = 1;
	public var hp = 1;

	var time_counter:Float = 0;
	var spot_time = 1; //time to spot
	var shoot_delay = 1;
	var reload_delay = 5;
	
	public function new(X, Y, B, Bmgr){
		super(X, Y);
		ball = B;
		bmgr = Bmgr;
		loadGraphic(AssetPaths.enemy__png, true, 32, 32);
		animation.add("search", [0, 1], 2, true);
		animation.add("alert", [2], 1, false);
		animation.add("shoot", [3], 1, false);
		animation.add("reload", [3, 4], 2, false);
		animation.play("search");
		visible = false;
		
		origin.x = 0;
	}
	
	public function reset_status(){
		time_counter = 0;
		hp = maxhp;
		state = 0;
	}
	
	public function Shoot():Void{
		var b = bmgr.request_bomb();
		
		if(b!=null){
			b.visible = true;
			b.y = y;
			b.reset_bomb(x, (b.height) + (Math.random() * (FlxG.height - (b.height * 2))));
		}
	}
	
	var reset_effect_timer:FlxTimer;
	public function onShot():Bool{
		color = FlxColor.RED;
		scale.x = scale.y = 1.5;
		if(reset_effect_timer == null)
			reset_effect_timer = new FlxTimer();
		
		reset_effect_timer.start(0.15, function(timer){
			color = FlxColor.WHITE;
			scale.x = scale.y = 1.0;
		});
		
		FlxG.sound.play(AssetPaths.enemy_die__wav);
		
		hp--;
		if(hp<=0){
			visible = false;
			hp = maxhp;
			(cast(FlxG.state, PlayState)).onKillEnemy(this);
			return true;
		}
		return false;
	}
	
	override public function update(elapsed:Float){
		super.update(elapsed);
		if (!visible) return;
		
		switch(state){
			case 0: //Search
				
			if (!ball.overlapsPoint(FlxG.mouse.getPosition()) || !ball.visible){
					animation.pause();
					animation.play("alert");
					time_counter += elapsed;
					
					if (time_counter >= spot_time){
						time_counter = 0;
						state++;
						animation.play("alert");
					}
			}else{
				animation.play("search");
				time_counter = 0;
				animation.resume();
			}

			case 2: //Shoot
			time_counter += elapsed;
			if (time_counter >= shoot_delay){
				time_counter = 0;
				Shoot();
				animation.play("reload");
				state++;
			}
				
			case 4: //reloading
			time_counter += elapsed;
			if(time_counter >= reload_delay){
				time_counter = 0;
				animation.play("search");
				state++;
			}
			
			default:
			if(animation.finished)
				state++;

			if (state > 4)
				state = 0;
		}
	}
}

class Bullet extends FlxSprite implements Target{
	public var foreground:Bool = true;
	public var dir:Float = 0;
	public var speed:Float = 3;
	public var bump:Int = 0;
	public var ball:Ball = null;
	public var ps:PlayState;
	public function new(X, Y, B){
		super(X, Y);
		ball = B;
		loadGraphic(AssetPaths.bullet__png, false, 16, 16);
		visible = false;
		ps = cast FlxG.state;
	}
	
	public function onShot():Bool{
		visible = false;
		return false;
	}
	
	override public function update(elapsed:Float){
		super.update(elapsed);
		if (!visible) return;
		
		var speedmod;
		if(foreground){
			color = FlxColor.WHITE;
			scale.x = scale.y = 1.0;
			speedmod = 1.0;
		}else{
			for (e in ball.bmgr.enemies){
				if (!e.visible) continue;
				
				if (overlaps(e)){
					visible = false;
					e.hp = 1;
					e.onShot();
					PlayState.total_kills++;
					return;
				}
			}
			color = FlxColor.GRAY;
			scale.x = scale.y = 0.33;
			speedmod = 0.33;
		}	
		
		var xx = Help.clamp(x, -width, FlxG.width+width);
		var yy = Help.clamp(y, -height, FlxG.height + height);
		
		if(xx != x || yy != y){
			bump--;
			if(bump <= 0){
				visible = false;
			}else{
				x = xx;
				y = yy;
				dir += Help.degtorad(180);
			}
		}else if (ball.visible){
			if (overlaps(ball)){
				if(!ps.ball_absorb){
					FlxG.collide(this, ball);
				}else{
					visible = false;
				}
			}
		}
		
		x += Math.cos(dir) * speed * speedmod;
		y -= Math.sin(dir) * speed * speedmod;
	}
}

class Bomb extends FlxSprite implements Target{
	public static var payload:Int = 3;
	public static var upspeed:Float = 2;
	public static var downspeed:Float = 3;
	
	var bmgr:BulletManager = null;
	var foreground:Bool = false;
	var destination:Int = 300;
	var ball:Ball;
	var ps:PlayState;
	public function new(X,Y,Bmgr){
		super(X, Y);
		bmgr = Bmgr;
		loadGraphic(AssetPaths.bomb__png, true, 64, 64);
		animation.add("alive", [0, 1, 2, 1], 10, true);
		animation.play("alive");
		visible = false;
		
		ps = cast FlxG.state;
		ball = ps.ball;
	}
	
	public function onShot():Bool{
		FlxG.sound.play(AssetPaths.explode__wav);
		visible = false;
		return false;
	}
	
	public function reset_bomb(X:Float, Dest:Float){
		foreground = false;
		x = X;
		destination = Std.int(Dest);
		visible = true;
	}
	
	override public function update(elapsed:Float){
		super.update(elapsed);
		
		if (!visible) return;
		
		if(!foreground){
			scale.x = scale.y = 0.33;
			color = FlxColor.GRAY;
			y -= upspeed;
			
			if(y <= -height * 3)
				foreground = true;
		}else{
			if(ball.visible){
				if (overlaps(ball)){
					if(ps.ball_absorb_bombs)
						visible = false;
				}
			}
			
			color = FlxColor.WHITE;
			scale.x = scale.y = 1.0;
			y += downspeed;
			if (y >= destination)
				explode();
		}
	}
	
	public function explode(){
		function do_explode(?t, bump){
			FlxG.sound.play(AssetPaths.explode__wav);
			var bullets = bmgr.request(payload);
			
			for(i in 0...bullets.length){
				var dir = Help.degtorad(i * (360 / payload));
				var bb = bullets[i];
				bb.dir = dir;
				bb.x = x + (width/2);
				bb.y = y + (height / 2);
				bb.foreground = foreground;
				bb.visible = true;
				bb.bump = bump;
			}
		}
		
		if(visible){
			visible = false;
			do_explode(null, 2);
		}else{
			visible = false;
			new FlxTimer().start(0.15, do_explode.bind(_, 0));
		}
	}
}

class Explosion extends FlxSprite{
	var ps:PlayState;
	var ball:Ball;
	var size_mode = true;
	public var is_active = false;
	public function new(X,Y){
		super(X,Y);
		loadGraphic(AssetPaths.xpl__png, true, 64, 64);
		animation.add("xpl", [1, 2, 3, 0], 30, false);
		ps = cast FlxG.state;
		ball = ps.ball;
	}
	
	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		if (!is_active) return;
		
		if(animation.finished){
			is_active = false;
			return;
		}
		
		if (overlaps(ball) && ball.visible){
			ps.onHitBall();
			is_active = false;
		}else{
			if (ps.check_xpl_world_collision(this))
				is_active = false;
		}
		
	}
}
class Ball extends FlxSprite{
	var hp:Int = 5;
	var hspd:Float = 3;
	var vspd:Float = 2;
	var speedmod:Float = 1;
	var speedLevel:Float = 0;
	var ps:PlayState;
	public var bmgr:BulletManager;
	public function new(X,Y){
		super(X,Y);
		loadGraphic(AssetPaths.ball__png, true, 128, 128);
		animation.add("s0", [5], 1, false);
		animation.add("s1", [4], 1, false);
		animation.add("s2", [3], 1, false);
		animation.add("s3", [2], 1, false);
		animation.add("s4", [1], 1, false);
		animation.add("s5", [0], 1, false);
		
		ps = cast FlxG.state;
		
		solid = true;
		immovable = true;
	}
	public function hit():Bool{
		hp--;
		FlxG.sound.play(AssetPaths.hit_marble__wav);
		speedLevel = 0;
		FlxG.camera.flash(FlxColor.RED, 0.2);
		animation.play('s$hp');
		if (hp <= 0){
			FlxG.sound.play(AssetPaths.hit_marble_2__wav);
			return true;
		}
		return false;
	}
	
	var elapsed_counter:Float = 0;
	override public function update(elapsed:Float):Void{
		super.update(elapsed);
		if (!visible) return;
		
		if(!ps.ball_constant_speed){
			elapsed_counter += elapsed;
			if(elapsed_counter >= 8){
				speedLevel ++;
				elapsed_counter = 0;
			}
		}else{
			speedLevel = 0;
		}
		
		if(overlapsPoint(FlxG.mouse.getPosition())){
			color = FlxColor.PURPLE;
		}else{
			color = FlxColor.WHITE;
		}
		
		speedmod = 1 + Math.log(Math.max(1, speedLevel));
		
		var ww = width;
		var hh = height;
		
		var xx = Help.clamp(x, 0, FlxG.width - ww);
		var yy = Help.clamp(y, 0, FlxG.height - hh);
		
		if (xx != x) hspd *= -1;		
		if (yy != y) vspd *= -1;
		
		x = xx;
		y = yy;
				
		x += hspd*speedmod;
		y += vspd*speedmod;
	}
	
	public function respawn(){
		hp = 5;
		speedmod = 1;
		x = (Math.random() * (FlxG.width - width)) + width/2;
		y = (Math.random() * (FlxG.height - height)) + height / 2;
		animation.play('s$hp');
		visible = true;
	}
}

class Shards extends FlxSprite{
	var vspd:Float = 0;
	var hspd:Float = 0;
	var grav:Float = 0.3;
	public function new(X,Y,i){
		super(X,Y);
		loadGraphic(AssetPaths.shards__png, true, 128, 128);
		animation.add("shard", [i], 1, false);
		animation.play("shard");		
		visible = false;
		reset_motion();
	}
	private function reset_motion(){
		hspd = (Math.random() < 0.5?1:-1)*(2 + Math.random()*4);
		vspd = -10 + (Math.random() * 3);
	}
	override public function update(elapsed:Float):Void{
		super.update(elapsed);

		if (!visible)
			return;
			
		vspd += grav;
		y += vspd;
		x += hspd;
		
		if (vspd > 20) vspd = 20;
		
		if(y > FlxG.height+height){
			reset_motion();
			visible = false;
		}
	}
}

class UpgradeBar extends FlxSprite{
	public var type:Int = 0;
	private var name:String = "clip size";
	public var maxed:Bool = false;
	var ps:PlayState;
	
	var txPrice:FlxText;
	public function new(X, Y, T){
		super(X, Y);
		loadGraphic(AssetPaths.upgrades__png, true, 32, 32);
		
		ps = cast FlxG.state;
		
		animation.add("clip size_1", [0], 1, false);
		animation.add("clip size_2", [5], 1, false);
		
		animation.add("reload_1", [1], 1, false);
		animation.add("reload_2", [6], 1, false);
		
		animation.add("free miss_1", [2], 1, false);
		animation.add("free miss_2", [7], 1, false);
		
		animation.add("gun level_1", [3], 1, false);
		animation.add("gun level_2", [8], 1, false);
		
		animation.add("big shot_1", [4], 1, false);
		animation.add("big shot_2", [9], 1, false);
		
		setType(T);
		
		txPrice = new FlxText(X, Y + height - 2, width, "PRICE");
		txPrice.size = 8;
		txPrice.color = FlxColor.WHITE;
		
		ps.add(txPrice);
		
		visible = true;
	}
	public function setType(set){
		type = set;
		switch(type){
			case 0:	name = "clip size";
			case 1:	name = "reload";
			case 2:	name = "free miss";
			case 3:	name = "gun level";
			case 4:	name = "big shot";
		}
	}
	
	private function active_upgrade(){
		switch(type){
			case 0:	ps.upgrade_clipsize(this);
			case 1:	ps.upgrade_reload(this);
			case 2:	ps.upgrade_freemiss(this);
			case 3:	ps.upgrade_gunlevel(this);
			case 4:	ps.upgrade_bigshot(this);
		}
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		if (!visible) return;
		
		if(maxed){
			color = FlxColor.GRAY;
			y = 584;
		}else{
			var stat = ps.update_upgradebar(this);
			
			txPrice.text = '$$${stat.price}';
			
			if(PlayState.carried_kills >= stat.price)
				color = FlxColor.WHITE;
			else
				color = FlxColor.GRAY;
				
			if(overlapsPoint(FlxG.mouse.getPosition())){
				animation.play('${name}_2');
				
				if(FlxG.mouse.justReleased){
					active_upgrade();
				}
				
			}else{
				animation.play('${name}_1');
			}
		}
		
	}
}
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
class PlayState extends FlxState
{
	public var bmgr:BulletManager;
	public var bg:FlxSprite;
	public var ball:Ball;
	public var crosshair:FlxSprite;
	public var shard:Array<Shards> = [];
	
	public var num_alive:Int = 0;
	
	//Gameplay variables
	public static var carried_kills:Int = 0; //kills held by the mouse
	public static var ball_kills:Int = 0; //kills shot into the ball
	public static var total_kills:Int = 0; //sum of all submitted kills

	public static var wave:Int = 0; //controls difficulty
	var missed:Int = 0;
	var missed_deadline:Float = 0;
	var missed_deadline_counter:Float = 0;
	
	//Upgrades -- last the whole game
	public static var clip_bullet:Int = 3;
	public static var clip_size:Int = 3; //number of shots before needing to reload
	public static var reload_time:Float = 2.0; //time to reload
	public static var reload_level:Int = 0;
	public static var free_misses:Int = 0; //numbr of shots that can be missed without dropping carries
	public static var gun_level:Int = 0; //improves shooting ability
	public static var big_shot:Bool = false; //makes shot hitbox bigger
	public static var biggest_ball:Int = 0;

	//Ball perks -- reset when ball breaks, activate automatically
	public var ball_absorb:Bool = false; //whether the ball will absorb bullets that it runs into
	public var ball_explosion:Bool = false; //whether the break will trigger a background explosion
	public var ball_constant_speed:Bool = false; //ball will move at constant speed always
	public var ball_absorb_bombs:Bool = false; //whether the ball will absorb bombs in addition to bullets
	public var ball_bigger:Bool = false; //ball size increases
	////////////////////
	
	public static function reset_values(){
		biggest_ball = 0;
		clip_bullet = 3;
		clip_size = 3;
		reload_time = 2.0;
		reload_level = 0;
		free_misses = 0;
		gun_level = 0;
		big_shot = false;
		carried_kills = 0;
		ball_kills = 0;
		total_kills = 0;
		wave = 0;
	}
	
	var txCarriedKills:FlxText;
	var txBallKills:FlxText;
	var txTotalKills:FlxText;
	var txWaveLabel:FlxText;
	
	private function CreateLabels(){
		txCarriedKills = new FlxText(0, 0);
		txCarriedKills.color = 0xffd201;
		txCarriedKills.borderStyle = FlxTextBorderStyle.OUTLINE;
		txCarriedKills.borderColor = FlxColor.BLACK;
		txCarriedKills.size = 24;
		
		txBallKills = new FlxText(0, 0);
		txBallKills.color = 0xffffff;
		txBallKills.borderStyle = FlxTextBorderStyle.OUTLINE;
		txBallKills.borderColor = FlxColor.BLACK;
		txBallKills.size = 32;
		txBallKills.fieldWidth = ball.width;
		txBallKills.alignment = FlxTextAlign.CENTER;
		
		txTotalKills = new FlxText(0, 0);
		txTotalKills.color = 0x715a77;
		txTotalKills.borderStyle = FlxTextBorderStyle.OUTLINE;
		txTotalKills.borderColor = FlxColor.WHITE;
		txTotalKills.size = 28;
		
		txWaveLabel = new FlxText(0, 0);
		txWaveLabel.color = 0x715a77;
		txWaveLabel.borderStyle = FlxTextBorderStyle.OUTLINE;
		txWaveLabel.borderColor = FlxColor.WHITE;
		txWaveLabel.size = 28;		
		
		txWaveLabel.x = 10;
		txWaveLabel.y = 10;
		
		txWaveLabel.text = "HP: 0";
		
		txTotalKills.x = 300;
		txTotalKills.y = 10;
		
		txTotalKills.text = "Kills: 0";
		
		txBallKills.text = "0";
		txCarriedKills.text = "0";
		
		add(txCarriedKills);
		add(txBallKills);
		add(txTotalKills);
		add(txWaveLabel);		
	}	
	
	override public function create():Void
	{
		super.create();
		
		FlxG.mouse.useSystemCursor = true;
		ball = new Ball(0, 0);

		bg = new FlxSprite(0, 0, AssetPaths.background__png);
		
		crosshair = new FlxSprite(0, 0);
		crosshair.loadGraphic(AssetPaths.crosshair__png, true, 48, 48);
		crosshair.animation.add("normal", [0], 1, false);
		crosshair.animation.add("reload", [1,2], 8, true);

		add(bg);
		
		var uiblock = new FlxSprite(0, 0);
		uiblock.makeGraphic(800, 52, 0xFF000000);
		add(uiblock);
		
		bmgr = new BulletManager(100, 50, 50, 50, ball);
		
		ball.bmgr = bmgr;
		
		//var enemy = new Enemy(370, 158, ball, bmgr);
		//enemy.visible = true;
		//add(enemy);
		
		spawn_enemy();
		
		add(ball);
		
		bmgr.add_xpl_to_scene();
		
		
		for (i in 0...9){
			var s = new Shards(0, 0, i);
			shard.push(s);
			add(s);
		}
		
		//Upgrades bar
		var sprUpgrades = [
			new UpgradeBar(600, 10, 0),
			new UpgradeBar(632, 10, 1),
			new UpgradeBar(664, 10, 2),
			new UpgradeBar(696, 10, 3),
			new UpgradeBar(728, 10, 4)
		];
		
		for (u in sprUpgrades)
			add(u);
		
		add(crosshair);
		
		CreateLabels();
	}
	
	
	var spawn_rails:Array<{x:Int, y:Int, w:Int}> = [
		{x: 263, y: 190, w: 247},
		{x: 525, y: 258, w: 247},
		{x: 564, y: 190, w: 247},
		{x: 295, y: 84, w: 247},
		{x: 0, y: 290, w: 226},
		{x: 78, y: 416, w: 35},
		{x: 171, y: 481, w: 35},
		{x: 293, y: 261, w: 35},
		{x: 455, y: 338, w: 35},
		{x: 362, y: 473, w: 35},
		{x: 555, y: 389, w: 35},
		{x: 717, y: 325, w: 35},
		{x: 717, y: 512, w: 35},
		{x: 555, y: 512, w: 35},
		{x: 624, y: 451, w: 35},
		{x: 131, y: 175, w: 35},
		{x: 62, y: 109, w: 35},
		{x: 62, y: 240, w: 35},
		
	];
	public function spawn_enemy(){
		var rail = spawn_rails[Math.floor(Math.random() * spawn_rails.length)];
		
		var e = bmgr.request_enemy();
		if (e != null){
			num_alive++;
			e.visible = true;
			e.reset_status();
			e.x = rail.x + (Math.random() * (rail.w - e.width));
			e.y = rail.y - e.height;
		}
	}
	
	public function onKillEnemy(?e:Enemy){
		num_alive--;
		if(num_alive <= 0)
			startWave(wave + 1);
	}	
	
	public function startWave(w:Int){
		wave = w;
		
		/*
			Enemy.maxhp++;
			Bomb.upspeed++;
			Bomb.downspeed++;
			Bomb.payload++;
		*/
		
		if (wave % 10 == 0)
			Bomb.payload++;
		
		if (wave % 30 == 0){
			Enemy.maxhp++;
		}
		
		
		var ctwe = Math.round(Math.log(wave)*3) + 1;
		for(ei in 0...ctwe)
			spawn_enemy();
	}
	
	var misses_counter:Int = 0;
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if(FlxG.keys.justReleased.M){
			if (FlxG.sound.volume != 0)
				FlxG.sound.volume = 0;
			else
				FlxG.sound.volume = 100;
		}
		
		var mpos = FlxG.mouse.getPosition();
		
		txCarriedKills.text = '$carried_kills';
		txBallKills.text = '$ball_kills';
		txTotalKills.text = 'Kills: $total_kills';
		txWaveLabel.text = 'HP: $playerhp';
		
		txCarriedKills.x = mpos.x;
		txCarriedKills.y = mpos.y - txCarriedKills.height;
		if(carried_kills == 0){
			txCarriedKills.scale.x = 1.0;
			txCarriedKills.scale.y = txCarriedKills.scale.x;
		}
		
		txCarriedKills.visible = carried_kills != 0;
		
		txBallKills.x = ball.x;
		txBallKills.y = ball.y + ball.height / 3;
		txBallKills.visible = ball.visible;
		
		crosshair.x = mpos.x - (crosshair.width/2);
		crosshair.y = mpos.y - (crosshair.height / 2);
		
		if(missed > 0){
			if (missed_deadline_counter >= missed_deadline){
				missed = 0;
				missed_deadline_counter = 0;
				onMissed();
			}else{
				missed_deadline_counter += elapsed;
			}
		}else{
			missed_deadline_counter = 0;
			missed = 0;
		}
		
		if(mpos.y > 52){
			if (FlxG.mouse.justPressed){
				if (clip_bullet > 0){
					onShoot(false);
				}
			}
			
			if (FlxG.mouse.justPressedRight){
				if (clip_bullet > 0){
					onShoot(true);
				}
			}
		}
		

		if(clip_bullet<=0){
			clip_bullet--;
			if (clip_bullet == -1){
				crosshair.animation.play("reload");
				new FlxTimer().start(reload_time, onReload);
			}
		}
			
		if(!ball.overlapsPoint(mpos) || !ball.visible){
			for (bullet in bmgr.bullets){
				if(bullet.visible && bullet.foreground){
					if (bullet.overlapsPoint(mpos)){
						bullet.visible = false;
						onHit();
					}
				}
			}
		}
		
		//crosshair.visible = xpl.animation.finished;
	}
	
	private function onMissed(){
		FlxG.sound.play(AssetPaths.miss__wav);
		misses_counter++;					
		if(misses_counter > free_misses)
			onDroppedCarries();
	}
	
	private function onShoot(single:Bool){
		var shots = [];
		var shot_type = single?0:gun_level;
		switch(shot_type){
			default:
				missed = 1;
				missed_deadline = 0.01;
				var xpl = bmgr.request_xpl(1)[0];
				if (xpl != null){
					
					if(big_shot){
						xpl.scale.x = xpl.scale.y = 1.0;
						xpl.updateHitbox();
					}else{
						xpl.scale.x = xpl.scale.y = 0.5;
						xpl.updateHitbox();
					}
					
					xpl.x = FlxG.mouse.x - (xpl.width / 2);
					xpl.y = FlxG.mouse.y - (xpl.height / 2);
					xpl.animation.play("xpl");
					xpl.is_active = true;
					shots.push(xpl);
				}
			case 1:
				missed = 1;
				missed_deadline = 0.01;

				shots = bmgr.request_xpl(2);
				for (i in 0...shots.length){
					var xpl = shots[i];
					
					if(big_shot){
						xpl.scale.x = xpl.scale.y = 1.0;
						xpl.updateHitbox();
					}else{
						xpl.scale.x = xpl.scale.y = 0.5;
						xpl.updateHitbox();
					}
					
					var offx = i * xpl.width / 2;
					var offy = i * -xpl.height / 2;
					
					xpl.x = (FlxG.mouse.x+offx) - (xpl.width / 2);
					xpl.y = (FlxG.mouse.y+offy) - (xpl.height / 2);
					xpl.is_active = true;
					xpl.animation.play("xpl");
				}
			case 2: //linear shot
				shots = bmgr.request_xpl(6);
				
				var spawn_delay = 0.015;
				
				missed = 1;
				missed_deadline = (shots.length * spawn_delay)+0.01;
				
				var xpl1 = shots[shots.length - 1];
				xpl1.x = (FlxG.mouse.x) - (xpl1.width / 2);
				xpl1.y = (FlxG.mouse.y) - (xpl1.height / 2);
				xpl1.animation.play("xpl");
				xpl1.is_active = true;
					
				if(big_shot){
					xpl1.scale.x = xpl1.scale.y = 1.0;
					xpl1.updateHitbox();
				}else{
					xpl1.scale.x = xpl1.scale.y = 0.5;
					xpl1.updateHitbox();
				}
				
				var ct = shots.length - 1;
				for (i in 0...ct){
					var st = spawn_delay * i;
					new FlxTimer().start(st, function(?t){
						var xpl = shots[i];
					
						if(big_shot){
							xpl.scale.x = xpl.scale.y = 1.0;
							xpl.updateHitbox();
						}else{
							xpl.scale.x = xpl.scale.y = 0.5;
							xpl.updateHitbox();
						}
						
						xpl.x = (FlxG.mouse.x) - (xpl.width / 2);
						xpl.y = (FlxG.mouse.y) - (xpl.height / 2);
						xpl.animation.play("xpl");
						xpl.is_active = true;
					});
				}
			case 3: //spiral shot
				shots = bmgr.request_xpl(10);
				
				var spawn_delay = 0.015;
				
				missed = 1;
				missed_deadline = (shots.length * spawn_delay)+0.01;
				
				var xpl1 = shots[shots.length - 1];
				xpl1.x = (FlxG.mouse.x) - (xpl1.width / 2);
				xpl1.y = (FlxG.mouse.y) - (xpl1.height / 2);
				xpl1.animation.play("xpl");
				xpl1.is_active = true;
					
				if(big_shot){
					xpl1.scale.x = xpl1.scale.y = 1.0;
					xpl1.updateHitbox();
				}else{
					xpl1.scale.x = xpl1.scale.y = 0.5;
					xpl1.updateHitbox();
				}
				
				var ct = shots.length - 1;
				for (i in 0...ct){
					var st = spawn_delay * i;
					new FlxTimer().start(st, function(?t){
						var xpl = shots[i];
					
						if(big_shot){
							xpl.scale.x = xpl.scale.y = 1.0;
							xpl.updateHitbox();
						}else{
							xpl.scale.x = xpl.scale.y = 0.5;
							xpl.updateHitbox();
						}
						
						var offx = Math.cos(Help.degtorad((360/ct)*i)) * (xpl.width);
						var offy = -Math.sin(Help.degtorad((360/ct)*i)) * (xpl.height);
						
						xpl.x = (FlxG.mouse.x+offx) - (xpl.width / 2);
						xpl.y = (FlxG.mouse.y+offy) - (xpl.height / 2);
						xpl.animation.play("xpl");
						xpl.is_active = true;
					});
				}
		}

		clip_bullet--;
	}
	
	public function check_xpl_world_collision(xpl:Explosion){
		var hit = false;
		for (enemy in bmgr.enemies){
			if (enemy.visible){
				if (enemy.overlaps(xpl)){
					missed--;
					hit = true;
					onShootTarget(enemy);
				}
			}
		}		
		for (bomb in bmgr.bombs){
			if(bomb.visible){
				if (bomb.overlaps(xpl)){
					missed--;
					hit = true;
					onShootTarget(bomb);
				}
			}
		}
		return hit;
	}
	
	private function onReload(?t){
		misses_counter = 0;
		clip_bullet = clip_size;
		crosshair.animation.play("normal");
		//play sound reload
	}
	
	private function onShootTarget(target:Target){
		var ret = target.onShot();
		
		if (ret){
			if(txCarriedKills.scale.x < 2.5){
				txCarriedKills.scale.x += 0.1;
				txCarriedKills.scale.y = txCarriedKills.scale.x;
			}
			carried_kills++;
		}
		
		return ret;
	}
	
	public static var carried_records:Array<Int> = [];
	function onDroppedCarries(){
		carried_records.push(carried_kills);
		carried_kills = 0;
	}
	
	public function onHitBall(){
		missed--;
		var ret = ball.hit();
		
		ball_kills += carried_kills;
		onUpdateBallKills();
		onDroppedCarries();
		
		if (ret){
			DeadBall();
			total_kills += ball_kills;
			ball_kills = 0;
			onUpdateBallKills();
		}else{
			if(ball_kills >= ball_perk_levels[4])
				ball_bigger = true;
		}
		
		if(ball_bigger){
			ball.scale.x = ball.scale.y = 1.5;
			ball.updateHitbox();
		}else{
			ball.scale.x = ball.scale.y = 1.0;
			ball.updateHitbox();
		}
		
		return ret;
	}
	
	var playerhp = 10;
	private function onHit(){
		playerhp--;
		if (playerhp <= 0)
			onGameOver();
		
		FlxG.sound.play(AssetPaths.hit__wav, 1.0, false);
			
		onDroppedCarries();
		camera.flash(FlxColor.RED, 0.1);
		camera.shake(0.015, 0.2);
	}
	
	private function DeadBall(){
		
		for (s in shard){
			s.x = ball.x;
			s.y = ball.y;
			s.visible = true;
		}
		
		if(ball_explosion){
			var blt = bmgr.request(ball_kills);
			
			for(i in 0...blt.length){
				var dir = Help.degtorad(i * (360 / blt.length));
				var bb = blt[i];
				bb.dir = dir;
				bb.x = FlxG.mouse.x;
				bb.y = FlxG.mouse.y;
				bb.foreground = false;
				bb.visible = true;
				bb.bump = 0;
			}
		}
		
		
		ball.visible = false;
		var t = new FlxTimer();
		t.start(10, SpawnBall);
	}
	
	private function SpawnBall(timer:FlxTimer){
		ball.visible = true;
		ball.respawn();
	}
	
	private function onGameOver(){
		total_kills += carried_kills + ball_kills;
		FlxG.switchState(new GameOverState());
	}
	
	////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////
	///Upgrades
	////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////

	public static var upgrade_prices = [
		//clip_size
		[1, 3, 5, 10, 10, 14, 16, 18, 20, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 30, 30, 30, 30, 30],
		
		//reload
		[5, 7, 10, 14, 18, 25, 30],
		
		//free misses
		[1, 4, 6, 8, 10, 14, 18, 22, 30],
		
		//gun level
		[10, 20, 40],
		
		//big shot
		[20]
	];
	
	
	public function update_upgradebar(bar:UpgradeBar):{current:Int, max:Int, price:Int}{
		switch(bar.type){
			case 0: //clip_size
				return {
					current: clip_size,
					max: upgrade_prices[0].length,
					price: upgrade_prices[0][clip_size - 3]
				};
			case 1: //reload_time
				return {
					current: reload_level,
					max: upgrade_prices[1].length,
					price: upgrade_prices[1][reload_level]
				};
			case 2: //free_misses
				return {
					current: free_misses,
					max: upgrade_prices[2].length,
					price: upgrade_prices[2][free_misses]
				};
			case 3: //gun_level
				return {
					current: gun_level,
					max: 3,
					price: upgrade_prices[3][gun_level]
				};
			case 4: //big_shot
				return {
					current: big_shot?0:1,
					max: 1,
					price: upgrade_prices[4][0]
				};
		}
		
		return null;
	}
	
	public function upgrade_clipsize(bar:UpgradeBar){
		var price = upgrade_prices[0][clip_size - 3];
		
		if(carried_kills >= price){
			carried_kills -= price;
			clip_size += 1;
			FlxG.sound.play(AssetPaths.buy__wav);
		}
		
		if (clip_size > upgrade_prices[0].length)
			bar.maxed = true;
	}
	
	public function upgrade_reload(bar:UpgradeBar){
		var price = upgrade_prices[1][reload_level];
		
		if(carried_kills >= price){
			carried_kills -= price;
			total_kills += price;
			reload_time *= 0.75;
			reload_level++;
			FlxG.sound.play(AssetPaths.buy__wav);
		}
		if (reload_level >= upgrade_prices[1].length)
			bar.maxed = true;
	}
	
	public function upgrade_freemiss(bar:UpgradeBar){
		var price = upgrade_prices[2][free_misses];
		
		if(carried_kills >= price){
			carried_kills -= price;
			total_kills += price;
			free_misses++;
			FlxG.sound.play(AssetPaths.buy__wav);
		}
		if (free_misses > upgrade_prices[2].length)
			bar.maxed = true;
	}
	
	public function upgrade_gunlevel(bar:UpgradeBar){
		var price = upgrade_prices[3][gun_level];
		
		if(carried_kills >= price && gun_level < 3){
			carried_kills -= price;
			total_kills += price;
			gun_level++;
			FlxG.sound.play(AssetPaths.buy__wav);
		}
		if (gun_level >= 3)
			bar.maxed = true;
	}
	
	public function upgrade_bigshot(bar:UpgradeBar){
		var price = upgrade_prices[4][0];
		
		if(carried_kills >= price){
			carried_kills -= price;
			total_kills += price;
			big_shot = true;
			FlxG.sound.play(AssetPaths.buy__wav);
		}
		if (big_shot)
			bar.maxed = true;
	}
	
	//////////////////
	//Ball Perks
	public static var ball_perk_levels:Array<Int> = [
		40,//ball_absorb
		10,//ball_explosion
		160,//ball_constant_speed
		90,//ball_absorb_bombs
		240 //ball_bigger
	];
	/*
	public var ball_absorb:Bool = false; //whether the ball will absorb bullets that it runs into
	public var ball_explosion:Bool = false; //whether the break will trigger a background explosion
	public var ball_constant_speed:Bool = false; //ball will move at constant speed always
	public var ball_absorb_bombs:Bool = false; //whether the ball will absorb bombs in addition to bullets
	public var ball_bigger:Bool = false; //ball size increases
	*/
	public function onUpdateBallKills(){
		if (ball_kills > biggest_ball)
			biggest_ball = ball_kills;
		
		if (ball_kills >= ball_perk_levels[0])
			ball_absorb = true;
		else
			ball_absorb = false;
			
		if (ball_kills >= ball_perk_levels[1])
			ball_explosion = true;
		else
			ball_explosion = false;
			
		if (ball_kills >= ball_perk_levels[2])
			ball_constant_speed = true;
		else
			ball_constant_speed = false;
			
		if (ball_kills >= ball_perk_levels[3])
			ball_absorb_bombs = true;
		else
			ball_absorb_bombs = false;
			
		if (ball_kills >= ball_perk_levels[2])
			ball_bigger = true;
		else
			ball_bigger = false;			
	}
}