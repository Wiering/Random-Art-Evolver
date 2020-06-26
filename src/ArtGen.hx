
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
import flash.display.BitmapData;
import flash.display.GradientType;
import flash.display.SpreadMethod;
import flash.display.Sprite;
import flash.filters.BitmapFilter;
import flash.filters.BlurFilter;
import flash.filters.ColorMatrixFilter;
import flash.filters.ConvolutionFilter;
import flash.filters.DisplacementMapFilter;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

class ArtGen
{
	public static var randSeed1: UInt = 0;
	public static var randSeed2: UInt = 0;
	
	public static function rnd (?n: Int = 0)
	{
		randSeed1 = (randSeed1 + 0x152 + randSeed2) << 1;
		randSeed2 = (randSeed2 ^ 0x259) + randSeed1;
		randSeed1 = ((randSeed1 << 1) + randSeed2) & 0xFFFF;
		randSeed2 = ((randSeed2 & 0xFF) << 8) + ((randSeed2 & 0xFF00) >> 8);
		if (n <= 0)
			return randSeed1;
		else
			return (randSeed1 % n);
	}
	
	
	public static function hex2 (i: Int): String
	{
		i &= 0xFF;
		var hex = "0123456789abcdef";
		return hex.charAt (i >> 4) + hex.charAt (i & 0xF);
	}
	
	public static function toHex (ba: ByteArray): String
	{
		var s: String = "";
		ba.position = 0;
		for (i in 0...ba.length)
			s += hex2 (ba.readUnsignedByte ());
		return s;
	}
	
	public static function fromHex (s: String): ByteArray
	{
		var valid: Bool = true;
		var hex = "0123456789abcdefABCDEF";
		var ba: ByteArray = new ByteArray ();
		
		s = StringTools.replace (s, " ", "");
		for (i in 0...s.length - 1)
			if (i % 2 == 0)
			{
				var c1: String = s.charAt (i);
				var p1: Int = hex.indexOf (c1);
				if (p1 >= 16) p1 -= 6;
				if (p1 >= 16 || p1 < 0) valid = false;
				var c2: String = s.charAt (i + 1);
				var p2: Int = hex.indexOf (c2);
				if (p2 >= 16) p2 -= 6;
				if (p2 >= 16 || p2 < 0) valid = false;
				ba.writeByte ((p1 << 4) + p2);
			}
		if (valid)
			return ba;
		else
			return null;
	}

	
	public static inline function rgb (r: Int, g: Int, b: Int): Int { return clipByte (b) + (clipByte (g) << 8) + (clipByte (r) << 16); }
	public static inline function rgba (r: Int, g: Int, b: Int, a: Int): Int { return clipByte (b) + (clipByte (g) << 8) + (clipByte (r) << 16) + (clipByte (a) << 24); }
	
	public static function clipByte (b: Int)
	{
		if (b < 0)
			return 0;
		else
			if (b > 0xFF)
				return 0xFF;
			else
				return b;
	}
	
	public var tw: Int;
	public var th: Int;
	public var bd: BitmapData;
	
	
	public var xx: Float;
	public var yy: Float;
	public var dxx: Float;
	public var dyy: Float;
	public var xxyyCounter: Int;
	
	
	public function new (w: Int, h: Int)
	{
		tw = w;
		th = h;
		bd = new BitmapData (w, h, true, 0);
		
	}
	
	
	function getByte (data: ByteArray): Int
	{
		if (Std.int (data.position) >= Std.int (data.length - 1))
			data.position = 0;
		return data.readUnsignedByte ();
	}
	
	function getRndPos (data: ByteArray): Int
	{
		var p: Int = getByte (data) + getByte (data);
		if (tw + th <= 512) p >>= 1;
		
		if (xxyyCounter % 2 == 0)
		{
			if (dxx != 0)
			{
				p = Std.int (xx);
				xx += dxx;
				xxyyCounter++;
			}
		}
		else
		{
			if (dyy != 0)
			{
				p = Std.int (yy);
				yy += dyy;
				xxyyCounter++;
			}
		}
		
		return p;
	}
	

	public function makeOpenSimplexNoise (bd: BitmapData, sizeX: Float, sizeY: Float)
	{
		var osn: OpenSimplexNoise = new OpenSimplexNoise (0);
		for (j in 0...bd.height)
			for (i in 0...bd.width)
			{
				var ii: Float = (i % Std.int (sizeX));
				var jj: Float = (j % Std.int (sizeY));
				ii = i;// % Std.int (sizeX);
				jj = j;// % Std.int (sizeY);
				ii /= sizeX; 
				jj /= sizeY;
				
				var value: Float = osn.eval2 (ii, jj);
				var color: Int = Std.int (128.0 + value * 127.0);
				
				bd.setPixel32 (i, j, rgba (color, color, color, 255));
			}
	}
	
	
	public function render (code: ByteArray, ?transparent: Bool = false): BitmapData
	{
		randSeed1 = 0;
		randSeed2 = 0;
		
		var data: ByteArray = new ByteArray ();
		for (i in 0...code.length)
			data.writeByte (code[i]);
		
		var s: Sprite = new Sprite ();
		
		bd.fillRect (new Rectangle (0, 0, tw, th), 0x00000000);
		
		if (code.length == 0)
			return bd;
		
		s.graphics.beginBitmapFill (bd);
		s.graphics.drawRect (0, 0, tw, th);
		s.graphics.endFill ();
		
		data.position = 0;
		
		var bdTmp: BitmapData = new BitmapData (tw, th, true, 0);
		var pn: Bool = false;
		var gf: Bool = false;
		
		var r: Int = getByte (data);
		var g: Int = getByte (data);
		var b: Int = getByte (data);
		var a: Int = 255;
		
		var rr: Int = getByte (data);
		var gg: Int = getByte (data);
		var bb: Int = getByte (data);
		var aa: Int = 255;
		
		if (! transparent)
		{
			s.graphics.beginFill (rgb ((r + rr) >> 1, (g + gg) >> 1, (b + bb) >> 1), 1.0);
			s.graphics.drawRect (0, 0, tw, th);
			s.graphics.endFill ();
		}
		
		xx = 0;
		yy = 0;
		xx = getRndPos (data);
		yy = getRndPos (data);
		dxx = 0;
		dyy = 0;
		xxyyCounter = 0;
		
		code.position = 0;
		
		while (code.position < code.length)
		{
			if (Std.int (data.position) >= Std.int (data.length - 32))
				data.position = 0;

			var opcode: Int = code.readUnsignedByte ();
			if (opcode > 0x80)
				opcode = (code[code.length - 1] & 0x3F) + 0x40;
			
			//haxe.Log.clear ();
			//trace (hex2 (opcode));
			
			if (opcode >= 0x40 && opcode < 0x80)
			{
				if (gf)
				{
					var m: Matrix = new Matrix ();
					var d: Int = getByte (data);
					if (d > 0xC0)
						m.createGradientBox (tw, th);
					else
						m.createGradientBox (getByte (data) + 1, getByte (data) + 1);
					m.rotate (getByte (data) * 2);
						
					var sm: SpreadMethod = (d & 0x3 == 0)? SpreadMethod.REFLECT : ((d & 0x3 == 1)? SpreadMethod.REPEAT : SpreadMethod.PAD);
					if (d > 0x80)
						s.graphics.beginGradientFill (GradientType.RADIAL, [rgb (r, g, b), rgb (rr, gg, bb)], [a, aa], [0, 255], m, sm);
					else
						s.graphics.beginGradientFill (GradientType.LINEAR, [rgb (r, g, b), rgb (rr, gg, bb)], [a, aa], [0, 255], m, sm);

				}
				else
					if (pn)
					{
						var m: Matrix = new Matrix ();
						if (getByte (data) > 0x80)
							m.rotate (getByte (data) * 2);
						if (getByte (data) > 0x80)
							m.scale ((getByte (data) + 1) / 8, (getByte (data) + 1) / 8);
						s.graphics.beginBitmapFill (bdTmp, m, true, true);
					}
					else
					{
						s.graphics.beginFill (rgb (r, g, b), a / 256);
					}
			}
			
			switch (opcode)
			{
				case  0:
					r = getByte (data);
					g = getByte (data);
					b = getByte (data);
					a = getByte (data);
					
				case  1:	r = getByte (data);
				case  2:	g = getByte (data);
				case  3:	b = getByte (data);
				case  4:	a = getByte (data);
				
				case  5:	r += getByte (data);
				case  6:	g += getByte (data);
				case  7:	b += getByte (data);
				case  8:	a += getByte (data);
				
				case  9:	r -= getByte (data);
				case 10:	g -= getByte (data);
				case 11:	b -= getByte (data);
				case 12:	a -= getByte (data);
				
				case 13:	a = 255;
				
				case 14:
					var x: Int = (getByte (data) * getByte (data)) >> 8;
					r += x;
					g += x;
					b += x;
				case 15:
					var x: Int = (getByte (data) * getByte (data)) >> 8;
					r -= x;
					g -= x;
					b -= x;
					
				case 16:
					rr = r;
					gg = g;
					bb = b;
					aa = a;
					
				case 17:
					var x: Int = (getByte (data) * getByte (data)) >> 8;
					rr = r + x;
					gg = g + x;
					bb = b + x;
					aa = a + x;
					
				case 18:
					var x: Int = (getByte (data) * getByte (data)) >> 8;
					rr = r - x;
					gg = g - x;
					bb = b - x;
					aa = a - x;
				
				case 19:
					rr = 255;
					gg = 255;
					bb = 255;
					
				case 20:
					aa = 255;
					
				case 21:
					rr = 0;
					gg = 0;
					bb = 0;
					
				case 22: 
					aa = 0;
					
				case 23:  r = r + r;
				case 24:  g = g + g;
				case 25:  b = b + b;
				case 26:  rr = r + r;
				case 27:  gg = g + g;
				case 28:  bb = b + b;
				
				case 29:  a = 0x80;
				
				case 30:  // perlin noise
					var base: Int = getByte (data) + 1;
					var bdSmall = new BitmapData (128, 128, true, 0);
					var p = new StitchedOptimizedPerlin (base, base, base, getByte (data), Std.int ((getByte (data) & 0x7) / 3) + 1, 0.5);
					p.fill (bdSmall, 16 << (getByte (data) & 3), 16 << (getByte (data) & 3), 0, true, getByte (data) > 0x80, (getByte (data) | getByte (data)) & 7, getByte (data) > 0xC0);
					var m = new Matrix ();
					m.scale (bdTmp.width / bdSmall.width, bdTmp.height / bdSmall.height);
					bdTmp.draw (bdSmall, m, null, null, null, true);
					
					if (getByte (data) > 0x40)
						bdTmp.colorTransform (new Rectangle (0, 0, tw, th), new ColorTransform (getByte (data) / 128, getByte (data) / 128, getByte (data) / 128, getByte (data) / 256, r, g, b, a));
					pn = true;
				case 31:  pn = false;
					
				case 32:  gf = true;  // gradient fill
				case 33:  gf = false;
				
				case 34:  s.graphics.lineStyle ((getByte (data) >> 6) * (getByte (data) >> 6) + 1, rgb (r, g, b), a / 255);
				case 35:  s.graphics.lineStyle ();
				
				case 36:
					dxx = (getByte (data) - 128) / 16;
					dyy = (getByte (data) - 128) / 16;
				case 37:
					dxx = 0;
					dyy = 0;
					
				case 38:
					r = r * 2;
					g = g * 2;
					b = b * 2;
					
				case 39:
					r = r >> 1;
					g = g >> 1;
					b = b >> 1;
					
				case 40:
					r = rr + (a >> 2);
					g = gg + (a >> 2);
					b = bb + (a >> 2);
					
				case 41:  a = 0x40;
				case 42:  a = 0xC0;
				
				case 43:  aa >>= 1;
				case 44:  aa = 0x80;
					
				case 45:
					r = (r + rr) >> 1;
					g = (g + gg) >> 1;
					b = (b + bb) >> 1;
					a = (a + aa) >> 1;
					
				case 46:
					var base: Int = getByte (data);
					bdTmp.noise (getByte (data), base, clipByte (base + getByte (data)), (getByte (data) | getByte (data)) & 7, getByte (data) > 0xC0);
					if (getByte (data) > 0x40)
						bdTmp.colorTransform (new Rectangle (0, 0, tw, th), new ColorTransform (getByte (data) / 128, getByte (data) / 128, getByte (data) / 128, getByte (data) / 256, r, g, b, a));
					pn = true;
					
					
					
					
					
				case 0x40:  // circle
					s.graphics.drawCircle (getRndPos (data), getRndPos (data), getByte (data) * getByte (data) / 256);
					s.graphics.endFill ();
					
				case 0x41:  // ellipse
					s.graphics.drawEllipse (getRndPos (data), getRndPos (data), getByte (data) * getByte (data) / 256, getByte (data) * getByte (data) / 256);
					s.graphics.endFill ();
					
				case 0x42:  // rect
					var w = getByte (data) * getByte (data) / 256 + 1;
					var h = getByte (data) * getByte (data) / 256 + 1;
					s.graphics.drawRect (getRndPos (data) - w / 2, getRndPos (data) - h / 2, w, h);
					s.graphics.endFill ();
					
				case 0x43:  // round rect
					var w = getByte (data) * getByte (data) / 256 + 1;
					var h = getByte (data) * getByte (data) / 256 + 1;
					s.graphics.drawRoundRect (getRndPos (data) - w / 2, getRndPos (data) - h / 2, w, h, getByte (data) / w, getByte (data) / h);
					s.graphics.endFill ();
					
				case 0x44:  // n circles
					for (i in 0...(getByte (data) >> 4) + 1)
						s.graphics.drawCircle (getRndPos (data), getRndPos (data), getByte (data) * getByte (data) / 256);
					s.graphics.endFill ();
				
				case 0x45:  // n curves
					s.graphics.moveTo (getRndPos (data), getRndPos (data));
					for (i in 0...(getByte (data) >> 5) + 1)
						s.graphics.curveTo (getRndPos (data), getRndPos (data), getRndPos (data), getRndPos (data));
					s.graphics.endFill ();
					
				case 0x46:  // n curves (moved)
					var dx: Int = getByte (data) - 0x80;
					var dy: Int = getByte (data) - 0x80;
					s.graphics.moveTo (getByte (data) + tw / 2 + dx, getByte (data) + th / 2 + dy);
					for (i in 0...(getByte (data) >> 5) + 1)
						s.graphics.curveTo (getByte (data) + tw / 2 + dx, getByte (data) + th / 2 + dy, getByte (data) + tw / 2 + dx, getByte (data) + th / 2 + dy);
					s.graphics.endFill ();
					
				case 0x47:
					var d: Float = getByte (data) * getByte (data) / (256) + 1;
					for (i in 0...getByte (data))
					{
						var x: Float = getRndPos (data);
						var y: Float = getRndPos (data);
						s.graphics.moveTo (x, y);
						s.graphics.lineTo (x + (getByte (data) - 128) / d, y + (getByte (data) - 128) / d);
					}
					
				case 0x48:
					var w = getByte (data) * getByte (data) / 256 + 1;
					var h = getByte (data) * getByte (data) / 256 + 1;
					s.graphics.drawRoundRectComplex (getRndPos (data) - w / 2, getRndPos (data) - h / 2, w, h, getByte (data) / 16, getByte (data) / 16, getByte (data) / 16, getByte (data) / 16);
					s.graphics.endFill ();
					
				case 0x49:  // fill all
					s.graphics.drawRect (0, 0, tw, th);
					s.graphics.endFill ();
					
					if (getByte (data) > 0x80)
						aa = aa >> 1;
					var d: Int = tw >> 2;
					s.graphics.beginFill (rgb (rr, gg, bb), aa);
					s.graphics.drawRect (-d, -d, tw + 2 * d, th + 2 * d);
					s.graphics.endFill ();
					
				case 0x4A:  // n circles
					s.graphics.endFill ();
					for (i in 0...(getByte (data) >> 4) + 1)
					{
						s.graphics.beginFill (rgb (r, g, b), a / 255);
						s.graphics.drawCircle (getRndPos (data), getRndPos (data), getByte (data) * getByte (data) / 256);
						s.graphics.endFill ();
					}
					
				case 0x4B:  // n circles, fade out
					s.graphics.endFill ();
					a = 0xFF;
					for (i in 0...(getByte (data) >> 4) + 1)
					{
						s.graphics.beginFill (rgb (r, g, b), a / 255);
						s.graphics.drawCircle (getRndPos (data), getRndPos (data), getByte (data) * getByte (data) / 256);
						s.graphics.endFill ();
						if (i % 4 == 0)
							a = (a >> 1) + (a >> 2);
					}
					a = 0xFF;

				case 0x4C:  // n curves, fade out
					s.graphics.endFill ();
					a = 0xFF;
					for (i in 0...(getByte (data) >> 4) + 1)
					{
						var dx: Int = getByte (data) - 0x80;
						var dy: Int = getByte (data) - 0x80;
						s.graphics.beginFill (rgb (r, g, b), a / 255);
						s.graphics.moveTo (getByte (data) + tw / 2 + dx, getByte (data) + th / 2 + dy);
						for (i in 0...(getByte (data) >> 5) + 1)
							s.graphics.curveTo (getByte (data) + tw / 2 + dx, getByte (data) + th / 2 + dy, getByte (data) + tw / 2 + dx, getByte (data) + th / 2 + dy);
						s.graphics.endFill ();
						if (i % 4 == 0)
							a = (a >> 1) + (a >> 2);
					}
					a = 0xFF;
					
				case 0x4D:  // threshold
					{
						bd.fillRect (new Rectangle (0, 0, tw, th), 0x00000000);
						bd.draw (s);
						bdTmp.fillRect (new Rectangle (0, 0, tw, th), 0x00000000);
						var op: String = (getByte (data) > 0x80)? "<" : ">";
						if (getByte (data) > 0x80) op += "=";
						if (getByte (data) > 0xF0) op = "==";
						bdTmp.threshold (bd, new Rectangle (0, 0, tw, th), new Point (0, 0), op, rgba (r, g, b, a), rgba (rr, gg, bb, aa));
						s.graphics.clear ();
						s.graphics.beginBitmapFill (bdTmp);
						s.graphics.drawRect (0, 0, tw, th);
						s.graphics.endFill ();
					}
					
				case 0x50, 0x51, 0x52, 0x53, 0x54:
					{
						bd.fillRect (new Rectangle (0, 0, tw, th), 0x00000000);
						bd.draw (s);
						bdTmp.fillRect (new Rectangle (0, 0, tw, th), 0x00000000);
						var i: Int = getByte (data);
						
						var f: BitmapFilter = null;
						switch (opcode - 0x50)
						{
							case 0:  f = new BlurFilter (i >> 4, i >> 4);
							case 1:  f = new BlurFilter (i >> 6, i >> 6);
							case 2:
								{
									var m: Array<Float> = new Array ();
									for (j in 0...4)
									{
										var d1: Int = (getByte (data) * getByte (data)) >> 8;
										var d2: Int = (getByte (data) * getByte (data)) >> 8;
										var d3: Int = (getByte (data) * getByte (data)) >> 8;
										var d4: Int = (getByte (data) * getByte (data)) >> 8;
										var d5: Int = (getByte (data) * getByte (data)) >> 8;
										m = m.concat ([d1/256, d2/256, d3/256, d4/256, d5/256]);
									}
									var f: BitmapFilter = new ColorMatrixFilter (m);
								}
							case 3:  f = new DropShadowFilter (getByte (data) >> 4, getByte (data) + getByte (data), rgb (r - rr, g - gg, b - bb), a, i >> 4, i >> 4, getByte (data) / 16);
							case 4:  f = new GlowFilter (rgb (rr, gg, bb), aa, i >> 4, i >> 4, getByte (data) / 16);
						}
						
						if (f != null) bdTmp.applyFilter (bd, new Rectangle (0, 0, tw, th), new Point (0, 0), f);
							
						s.graphics.clear ();
						s.graphics.beginBitmapFill (bdTmp);
						s.graphics.drawRect (0, 0, tw, th);
						s.graphics.endFill ();
					}
				case 0x55:
					{
						var k: Int = (2 << (getByte (data) % 5)) << 3;
						if (k < 8) k = 8;
						if (k > 128) k = 128;
						for (j in 0...Std.int (th / k) + 2)
							for (i in 0...Std.int (tw / k) + 2)
								if ((i + j) % 2 == 0)
									s.graphics.drawRect ((i - 1) * k, (j - 1) * k, k, k);
						s.graphics.endFill ();
					}
				case 0x56:
					{
						s.graphics.endFill ();
						var k: Int = (2 << (getByte (data) % 5)) << 3;
						
						var l: Int = getByte (data);
						randSeed1 = getByte (data);
						randSeed2 = getByte (data);
						if (k < 8) k = 8;
						if (k > 64) k = 64;
						for (j in 0...Std.int (th / k) + 2)
						{
							for (i in 0...Std.int (tw / k) + 2)
							{
								s.graphics.beginFill (rgb (r, g, b), (rnd (0x100) ^ l ^ getByte (data)) / 255);
								s.graphics.drawRect ((i - 1) * k, (j - 1) * k, k, k);
								s.graphics.endFill ();
							}
							l = getByte (data);
						}
					}
				case 0x57:  // colortransform
					{
						s.graphics.endFill ();
						bdTmp.fillRect (new Rectangle (0, 0, tw, th), 0x00000000);
						bdTmp.draw (s);
						bdTmp.colorTransform (new Rectangle (0, 0, tw, th), new ColorTransform (getByte (data) / 128, getByte (data) / 128, getByte (data) / 128, getByte (data) / 255, (getByte (data) >> 2) - 32, (getByte (data) >> 2) - 32, (getByte (data) >> 2) - 32, (getByte (data) >> 2) - 32));
						//s.graphics.clear ();
						s.graphics.beginBitmapFill (bdTmp);
						s.graphics.drawRect (0, 0, tw, th);
						s.graphics.endFill ();
					}
					
					
				case 0x58:
					
					{
						var ap: Array<Point> = new Array();
						
						for (i in 0...(getByte (data) >> 4) + 1)
							ap.push (new Point (rnd (tw), rnd (th)));
						var w = getByte (data) >> 2;
						if (w > 16) w = 16;
						var d = (getByte (data) - 128) >> 4;
						var c = (getByte (data)) >> 4 + 1;
						for (i in 0...w + 1)
							for (p in ap)
							{
								var sz = w*c - i*c;
								s.graphics.beginFill (rgb (r + i * d, g + i * d, b + i * d));
								for (xx in -1...2)
									for (yy in -1...2)
										s.graphics.drawEllipse(p.x - sz + xx*tw, p.y - sz + yy*th, 2*sz, 2*sz);
								s.graphics.endFill ();
							}
						
						ap = null;
					}
					
				
				default:
				
			}
			
			
		}
		
		bd.fillRect (new Rectangle (0, 0, tw, th), 0x00000000);
		bd.draw (s);
		return bd;
	}
	
	
	public static function generate (sizeX: Int, sizeY: Int, code: String, ?transparent: Bool): BitmapData
	{
		return new ArtGen (sizeX, sizeY).render (fromHex (code), transparent);
	}
}