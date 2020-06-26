
/*
	Copyright (c) 2010, Wiering Software

	This software is provided 'as-is', without any express or implied
	warranty. In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:

		1. The origin of this software must not be misrepresented; you must not
		claim that you wrote the original software. If you use this software
		in a product, an acknowledgment in the product documentation would be
		appreciated but is not required.

		2. Altered source versions must be plainly marked as such, and must not be
		misrepresented as being the original software.

		3. This notice may not be removed or altered from any source
		distribution.
*/

import flash.display.Bitmap;
import flash.display.Loader;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.Lib;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.utils.ByteArray;
import haxe.Log;
import flash.display.BitmapData;
import flash.geom.Matrix;
import haxe.remoting.FlashJsConnection;
import flash.geom.ColorTransform;
import openfl.Assets;
import openfl.desktop.Clipboard;
import openfl.desktop.ClipboardFormats;


import ArtGen;

class Box
{
	public static var boxList: List<Box> = new List ();
	public static var all: List<Box> = new List ();

	public static var TW: Int = 512;
	public static var TH: Int = 512;
	public static var W: Int = 128;
	public static var H: Int = 128;
	
	static var START_LENGTH: Int = 10;
	
	public var ag: ArtGen;
	public var code: ByteArray;
	public var bmp: Bitmap;
	
	public var lastCode: Array<ByteArray>;
	public var newCode: ByteArray;
	
	public var n: Int;
	
	public var viewer: Bool;
	
	public static var vBox: Box;
	
	
	
	public static function writeString (x: Int, y: Int, s: String, color: Int, ?backColor: Int = 0, ?bmTarget: Bitmap = null)
	{
		var bdAscii = Assets.getBitmapData ("Assets/ascii.png");
		var bd: BitmapData = new BitmapData (8 * s.length, 16, true, backColor);
		
		var m: Matrix = new Matrix ();
		var ct: ColorTransform = new ColorTransform ((color & 0xFF) / 255.0, ((color >> 8) & 0xFF) / 255.0, ((color >> 16) & 0xFF) / 255.0, 1);
		for (i in 0...s.length)
		{
			var c: Int = s.charCodeAt (i);
			var xp: Int = 8 * (c & 0xF);
			var yp: Int = 16 * (c >> 4);
			m.identity ();
			m.translate (-xp + i * 8, -yp);
			bd.draw (bdAscii, m, ct, null, new Rectangle (i * 8, 0, 8, 16));
		}
		
		var target: Sprite = Main.screen;
		if (bmTarget == null)
		{
			target.graphics.beginFill (0xFFFFFF, 1.0);
			target.graphics.drawRect (x, y, bd.width, bd.height);
			target.graphics.endFill ();
			
			m.identity ();
			m.translate (x, y);
			target.graphics.beginBitmapFill (bd, m, false, false);
			target.graphics.drawRect (x, y, bd.width, bd.height);
			target.graphics.endFill ();
		}
		
		if (bmTarget != null)
		{
			m.identity ();
			m.scale (2.0, 2.0);
			bmTarget.bitmapData.draw (bd, m);
		}
	}
	
	
	
	
	public static function setTexSize (tw: Int, th: Int)
	{
		TW = tw;
		TH = th;
		for (b in Box)
			b.reset ();
		vBox.reset ();
		vBox.render ();
	}
	
	public function reset ()
	{
		ag = new ArtGen (TW, TH);
		
		bmp.bitmapData = ag.bd;
		
		bmp.scaleX = W / TW;
		bmp.scaleY = H / TH;
		
		lastCode = new Array ();
		
		if (viewer)
		{
			bmp.scaleX = 1.0;
			bmp.scaleY = 1.0;
			bmp.x = (Main.screen.stage.stageWidth - 512) + (512 - bmp.width) / 2;
			bmp.y = (512 - bmp.height) / 2;
		}
	}
	
	
	public function new (x: Int, y: Int, screen: Sprite, ?v: Bool = false)
	{
		bmp = new Bitmap ();
		bmp.x = x * W;
		bmp.y = y * H;
		
		randomData ();
		
		viewer = v;
		
		reset ();
		
		newCode = null;
		
		n = boxList.length;
		
		if (viewer)
		{
			vBox = this;
			bmp.visible = false;
		}
		else
			boxList.add (this);
		all.add (this);
			
		screen.addChild (bmp);
	}
	
	
	public function randomData ()
	{
		code = new ByteArray ();
		for (i in 0...START_LENGTH)
			code.writeByte (Std.int (Math.random () * 256));
	}
	
	
	public function mutate ()
	{
		lastCode.push (copyBA (code));
		if (lastCode.length > 100)
			lastCode = lastCode.slice (lastCode.length - 100);
		
		var n: Int = Main.speed;
		if (n == 0)
		{
			code = copyBA (vBox.code);
			n = 1;
		}
		
		for (i in 0...n)
		{
			if (Math.random () < 0.1)
			{
				if (code.length > 1 && Math.random () < 0.5)
					code.length--;
				else
				{
					code.position = code.length;
					code.writeByte (Std.int (Math.random () * 256));
				}
			}
			else
			{
				code.position = Std.int (Math.random () * code.length);
				code.writeByte (Std.int (Math.random () * 256));
			}
		}
	}
	
	public static function copyBA (ba: ByteArray): ByteArray
	{
		var b: ByteArray = new ByteArray();
		if (ba != null)
		{
			b.length = ba.length;
			for (i in 0...ba.length)
				b[i] = ba[i];
		}
		return b;
	}
	
	public static function copyBAA (baa: Array<ByteArray>): Array<ByteArray>
	{
		var a: Array<ByteArray> = new Array ();
		for (i in 0...baa.length)
		{
			a.push (copyBA (baa[i]));
		}
		return a;
	}
	
	public static function incLen ()
	{
		for (b in Box.all)
		{
			b.code.position = b.code.length;
			b.code.writeByte (Std.int (Math.random () * 256));
		}
		if (Box.vBox.bmp.visible)
		{
			Box.vBox.render ();
		}
	}
	
	public static function decLen ()
	{
		for (b in Box.all)
		{
			if (b.code.length > 1)
				b.code.length--;
		}
		if (Box.vBox.bmp.visible)
		{
			Box.vBox.render ();
		}
	}
	
	public function cloneFrom (c: ByteArray, lca: Array<ByteArray>)
	{
		if (lca != null)
		{
			newCode = copyBA (c);
			lastCode = copyBAA (lca);
		}
	}
	
	
	static var lastCodeLength: Int = 0;
	
	public function render ()
	{
		if (newCode != null)
		{
			code = newCode;
			newCode = null;
			
			if (!viewer)
				mutate ();
		}
		
		if (code != null)
		{
			ag.render (code, Main.transparent);
		
			if (viewer)
				if (Main.screen.stage.focus == null)
				{
		#if USE_TEXTFIELD
					Main.tf.text = ArtGen.toHex (code);
					Main.tf.selectable = true;
			#if flash
					Main.tf.alwaysShowSelection = true;
			#end
					Main.tf.setSelection (0, Main.tf.text.length);
		#else
					Main.tfText = ArtGen.toHex (code);
					var s: String = Main.tfText;
					while (s.length < lastCodeLength)
						s = s + " ";
					lastCodeLength = Main.tfText.length;
					writeString (16, 512 + 16, s, 0xFF000000, 0);
		#end
				}
			bmp.visible = true;
		}
		else
			bmp.visible = false;
			
		// writeString(0, 0, ArtGen.toHex(code), 0xFF8000, bmp);  // show code for each box
	}
	
	public static function iterator ()
	{
		return boxList.iterator ();
	}
}


class Main 
{
	public static var screen: Sprite;
	public static var frame: Int = 0;

#if USE_TEXTFIELD
	public static var tf: TextField;
#else
	public static var tfText: String = "";
#end
	
	var artgen: ArtGen;
	var bmp: Bitmap;
	var code: ByteArray;
	
	public static var transparent: Bool = false;
	public static var speed: Int = 1;
	public static var paused: Bool = false;
	
	var undoCode: Array<ByteArray>;
	
	public function new ()
	{
		screen = new Sprite ();
		Lib.current.addChild (screen);
		screen.addEventListener (Event.ENTER_FRAME, onEnterFrame);
	}
	
	public function onEnterFrame (e: Event)
	{
		if (frame == 0)
		{
			Lib.current.addChild (screen);
			Lib.current.stage.addEventListener (MouseEvent.CLICK, onClick);
			Lib.current.stage.addEventListener (KeyboardEvent.KEY_DOWN, onKeyDown);
			Lib.current.stage.addEventListener (KeyboardEvent.KEY_UP, onKeyUp);
			
			for (j in 0...4)
				for (i in 0...4)
					new Box (i, j, screen);
					
			new Box (4, 0, screen, true);
			
			speed = 1;
			undoCode = new Array ();
			
			screen.graphics.beginFill (0xFFFFFF, 1.0);
			screen.graphics.drawRect (0, 0, screen.stage.stageWidth, screen.stage.stageHeight);
			screen.graphics.endFill ();
	
		#if USE_TEXTFIELD
			tf = new TextField ();
			tf.x = 12;
			tf.y = 512 + 12;
			tf.width = screen.width - 2 * 12;
			tf.type = TextFieldType.INPUT;
			tf.addEventListener (Event.CHANGE, onTextChange);
			tf.wordWrap = true;
			screen.addChild (tf);
		#else
			tfText = "";
		#end
		}

		var f: Int = frame % Box.boxList.length;
		
		if (!paused)
			for (b in Box)
				if (f == b.n)
				{
					b.mutate ();
					b.render ();
				}
				
		frame++;
	}
	
	public function onTextChange (e: Event)
	{
	#if USE_TEXTFIELD
		if (tf.text != "")
		{
			var ba: ByteArray = ArtGen.fromHex (tf.text);
			if (ba != null)
			{
				if (Box.vBox.code != null)
					saveUndo (Box.vBox);
				Box.vBox.code = ba;
				Box.vBox.lastCode.push (Box.copyBA (ba));
				Box.vBox.render ();
			}
		}
	#else
		if (tfText != "")
		{
			var ba: ByteArray = ArtGen.fromHex (tfText);
			if (ba != null)
			{
				if (Box.vBox.code != null)
					saveUndo (Box.vBox);
				Box.vBox.code = ba;
				Box.vBox.lastCode.push (Box.copyBA (ba));
				Box.vBox.render ();
			}
		}
	#end
	}
	
	

	
	public function undo ()
	{
		var c: ByteArray = undoCode.pop ();
		if (undoCode.length == 0)
		{
			Box.vBox.bmp.visible = false;
	#if USE_TEXTFIELD
			tf.text = "";
	#else
			tfText = "";
	#end
		}
		else
		{
			Box.vBox.cloneFrom (c, []);
			Box.vBox.render ();
		}
	}
	
	public function saveUndo (b: Box)
	{
		undoCode.push (Box.copyBA (b.code));
	}
	
	public function onKeyDown (e: KeyboardEvent)
	{
		if (e.ctrlKey)
		{
	#if USE_TEXTFIELD
			screen.stage.focus = tf;
		#if flash
			tf.alwaysShowSelection = true;
		#end
			tf.selectable = true;
			tf.setSelection (0, Main.tf.text.length);
	#end
		}
		if (e.keyCode == 13)
			if (screen.stage.focus != null)
			{
				screen.stage.focus = null;
				Box.vBox.render ();
			}
			else
				for (a in Box)
					a.cloneFrom (Box.vBox.code, Box.vBox.lastCode);
		
		if (e.keyCode == 8)
			if (screen.stage.focus == null)
				if (e.shiftKey && Box.vBox.lastCode != [])
				{
					var ba: ByteArray = Box.vBox.code;
					Box.vBox.code = Box.vBox.lastCode.pop ();
					
					Box.vBox.render ();
				}
				else
					undo ();
		if (e.keyCode >= "0".charCodeAt (0) && e.keyCode <= "9".charCodeAt (0))
			speed = e.keyCode - "0".charCodeAt (0);
		if (e.keyCode == "T".charCodeAt (0))
		{
			transparent = !transparent;
			
			if (transparent)
			{
				screen.graphics.beginFill (0x808080, 1.0);
				screen.graphics.drawRect (0, 0, screen.stage.stageWidth, 512);
				screen.graphics.endFill ();
				var g = 16;
				var h = Std.int (128 / g);
				for (y in 0...Std.int (512 / g))
					for (x in 0...Std.int (1024 / g))
					{
						var i = (Std.int (x / h) + Std.int (y / h)) % 2;
						if (x * g >= (Main.screen.stage.stageWidth - 512)) i = 0;
						if ((x + y + i) % 2 == 0)
						{
							screen.graphics.beginFill ((i == 0)? 0x909090 : 0x707070, 1.0);
							screen.graphics.drawRect (x * g, y * g, g, g);
							screen.graphics.endFill ();
						}
					}
			}
			Box.vBox.render ();
		}
		if (e.keyCode == "P".charCodeAt (0))
			paused = !paused;

		if (e.keyCode == "R".charCodeAt (0))
		{
			for (b in Box.all)
				b.randomData ();
			Box.vBox.bmp.visible = false;
		}
		
		
		
		if (e.keyCode == "S".charCodeAt (0))
			if (Box.TW == 256)
				Box.setTexSize (512, 512);
			else
				Box.setTexSize (256, 256);
		
		if (e.charCode == "+".charCodeAt (0))
			Box.incLen ();
			
		if (e.charCode == "-".charCodeAt (0))
			Box.decLen ();
		
	#if !USE_TEXTFIELD
		if (e.keyCode == "C".charCodeAt (0))
		{
			Clipboard.generalClipboard.setData (ClipboardFormats.TEXT_FORMAT, tfText);
		}
		if (e.keyCode == "V".charCodeAt (0))
		{
			tfText = Clipboard.generalClipboard.getData (ClipboardFormats.TEXT_FORMAT);
			onTextChange (null);
		}
	#end
	}
	
	public function onKeyUp (e: KeyboardEvent)
	{
		if (e.ctrlKey)
			screen.stage.focus = null;
	}
	
	public function onClick (e: MouseEvent)
	{
		var mx = screen.mouseX;
		var my = screen.mouseY;
		
		for (b in Box)
		{
			if (mx >= b.bmp.x && mx < b.bmp.x + b.bmp.width)
				if (my >= b.bmp.y && my < b.bmp.y + b.bmp.height)
				{
					if (Box.vBox.code != null)
						saveUndo (Box.vBox);
					Box.vBox.cloneFrom (b.code, b.lastCode);
					for (a in Box)
						if (a != b)
							a.cloneFrom (b.code, b.lastCode);
							
					if (e.shiftKey)
					for (a in Box)
						if (a != b)
						{
							a.bmp.bitmapData.fillRect (a.bmp.bitmapData.rect, 0);
							a.bmp.bitmapData.draw (b.bmp.bitmapData);
						}
							
					Box.vBox.render ();
				}
		}
		var b = Box.vBox;
		if (mx >= b.bmp.x && mx < b.bmp.x + b.bmp.width)
			if (my >= b.bmp.y && my < b.bmp.y + b.bmp.height)
			{
				for (a in Box)
					a.cloneFrom (b.code, b.lastCode);
			}
	}
	
	
	static function main ()
	{
		new Main ();
	}
	
}