package;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxG;
import flixel.animation.FlxPrerotatedAnimation;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
/**
 * ...
 * @author Alejandro Ramallo
 */
class ScoreLine extends FlxGroup{
	public static var LABEL_WIDTH:Int = 100;
	public static var VALUE_WIDTH:Int = 300;
	
	public var label:FlxText;
	public var value:FlxText;
	public var perfect:Bool = false;
	
	public var ltxt:String;
	public var val:Float;
	public var max:Float;
	public function new(?maxsize, L:String, V:Float, M:Float){
		super(maxsize);
		
		val = V;
		max = M;
		
		ltxt = L;
				
		label = new FlxText(0, 0);
		label.width = LABEL_WIDTH;
		label.alignment = FlxTextAlign.RIGHT;
		
		value = new FlxText(0, 0);
		value.width = VALUE_WIDTH;
		value.alignment = FlxTextAlign.LEFT;
		
		add(label);
		add(value);
		
		if (val >= max) perfect = true;
	}
	
	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		
		label.text = '$ltxt:';
		label.color = 0x715a77;
		label.size = 18;
		value.size = 14;
		value.x = label.x + label.width;
		value.y = (label.y + label.height) - value.height;
		
		if(perfect){
			value.color = 0x00d784;
			value.text = '$val / $max  [PERFECT!!]';
		}else{
			value.color = 0x715a77;
			value.text = '$val / $max';
		}
	}
}
class GameOverState extends FlxState
{	
	var bg:FlxSprite;
	var txWave:FlxText;
	var txKills:FlxText;
	
	var scores:Array<ScoreLine> = [];
	
	override public function create():Void
	{
		super.create();
		
		bg = new FlxSprite(0, 0, AssetPaths.gameover__png);
		add(bg);
		
		txWave = new FlxText(185, 340);
		txKills = new FlxText(0, 0);
		
		txWave.color = 0xffd500;
		txWave.borderStyle = FlxTextBorderStyle.OUTLINE;
		txWave.borderColor = FlxColor.BLACK;
		txWave.size = 24;
		
		txKills.color = 0xff8a00;
		txKills.borderStyle = FlxTextBorderStyle.OUTLINE;
		txKills.borderColor = FlxColor.BLACK;
		txKills.size = 24;
		
		txWave.text = 'Wave: ${PlayState.wave}';
		txKills.text = 'Total Kills: ${PlayState.total_kills}';
		
		add(txKills);
		add(txWave);
		
		scores = [
			new ScoreLine(null,
				"Clip Size",
				PlayState.clip_size,
				PlayState.upgrade_prices[0].length
			),
			new ScoreLine(null,
				"Reload Speed",
				PlayState.reload_level,
				PlayState.upgrade_prices[1].length
			),
			new ScoreLine(null,
				"Free Misses",
				PlayState.free_misses,
				PlayState.upgrade_prices[2].length
			),
			new ScoreLine(null,
				"Weapon Level",
				PlayState.gun_level,
				PlayState.upgrade_prices[3].length
			),
			new ScoreLine(null,
				"Big Shot",
				PlayState.big_shot?1:0,
				1
			),
			new ScoreLine(null,
				"Biggest Ball",
				PlayState.biggest_ball,
				PlayState.ball_perk_levels[PlayState.ball_perk_levels.length - 1]
			)
		];
		
		for(l in scores) add(l);
		
		camera.flash();
		
		Sys.println('Carried Records: (${PlayState.carried_records.length})');
		for(i in PlayState.carried_records){
			Sys.print('$i,');
		}
		Sys.print('\n');
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		txKills.x = txWave.x + txWave.width + 10;
		txKills.y = txWave.y;
		
		var VPADDING = 2;
		
		var last:ScoreLine = null;
		for (l in scores){
			l.label.x = txWave.x;
			
			if (last == null)
				l.label.y = txKills.y + txKills.height + VPADDING;
			else
				l.label.y = last.label.y + last.label.height + VPADDING;
			
			last = l;
		}
		
		
		if (FlxG.keys.justReleased.SPACE){
			PlayState.reset_values();
			FlxG.resetGame();
		}
	}
}