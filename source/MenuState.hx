package;
import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
/**
 * ...
 * @author Alejandro Ramallo
 */
class MenuState extends FlxState{

	var state = 0;
	
	var bg:FlxSprite;
	var ins_1:FlxSprite;
	var ins_2:FlxSprite;
	var ins_3:FlxSprite;
	
	override public function create():Void 
	{
		super.create();
		
		bg = new FlxSprite(0, 0, AssetPaths.menu_bg__png);
		ins_1 = new FlxSprite(0, FlxG.height, AssetPaths.menu_bg_instruct__png);
		ins_2 = new FlxSprite(0, FlxG.height, AssetPaths.menu_bg_instruct2__png);
		ins_3 = new FlxSprite(0, FlxG.height, AssetPaths.menu_bg_instruct3__png);
		
		add(bg);
		add(ins_1);
		add(ins_2);
		add(ins_3);
		
		FlxTween.tween(ins_1, {x: 0, y: 0}, 0.25);
		FlxG.camera.flash(FlxColor.WHITE, 2);
	}
	
	var elapsed_ct:Float = 0;
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		if(FlxG.keys.justReleased.SPACE){
			FlxG.switchState(new PlayState());
		}
		
		switch(state){
			case 0:
				if ( FlxG.keys.justReleased.ANY){
					FlxTween.tween(ins_1, {x: -FlxG.width, y: 0}, 0.15);
					FlxTween.tween(ins_3, {x: 0, y: 0}, 0.15);
					state = 1;
				}
				
			case 1:
				if (FlxG.keys.justReleased.LEFT){
					FlxTween.tween(ins_1, {x: 0, y: 0}, 0.15);						
					FlxTween.tween(ins_3, {x: 0, y: FlxG.height}, 0.15);
					state = 0;
				}else
				if ( FlxG.keys.justReleased.ANY){
					FlxTween.tween(ins_3, {x: -FlxG.width, y: 0}, 0.15);
					FlxTween.tween(ins_2, {x: 0, y: 0}, 0.15);
					state = 2;
				}
				
			case 2:
				if (FlxG.keys.justReleased.LEFT){
					FlxTween.tween(ins_3, {x: 0, y: 0}, 0.15);						
					FlxTween.tween(ins_2, {x: 0, y: FlxG.height}, 0.15);
					state = 0;
				}
		}
	}
	
}