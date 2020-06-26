/**
Title:      Perlin noise
Version:    1.3
Author:      Ron Valstar
Author URI:    http://www.sjeiti.com/
Original code port from http://mrl.nyu.edu/~perlin/noise/
and some help from http://freespace.virgin.net/hugo.elias/models/m_perlin.htm
AS3 optimizations by Mario Klingemann http://www.quasimondo.com
Haxe port and optimization by Nicolas Cannasse http://haxe.org
*/

// stitching/repeating by Mike Wiering


import flash.display.BitmapData;
import haxe.io.Bytes;

class StitchedOptimizedPerlin {

	private static var P = [
		151,160,137,91,90,15,131,13,201,95,
		96,53,194,233,7,225,140,36,103,30,69,
		142,8,99,37,240,21,10,23,190,6,148,
		247,120,234,75,0,26,197,62,94,252,
		219,203,117,35,11,32,57,177,33,88,
		237,149,56,87,174,20,125,136,171,
		168,68,175,74,165,71,134,139,48,27,
		166,77,146,158,231,83,111,229,122,
		60,211,133,230,220,105,92,41,55,46,
		245,40,244,102,143,54,65,25,63,161,
		1,216,80,73,209,76,132,187,208,89,
		18,169,200,196,135,130,116,188,159,
		86,164,100,109,198,173,186,3,64,52,
		217,226,250,124,123,5,202,38,147,118,
		126,255,82,85,212,207,206,59,227,47,
		16,58,17,182,189,28,42,223,183,170,
		213,119,248,152,2,44,154,163,70,221,
		153,101,155,167,43,172,9,129,22,39,
		253,19,98,108,110,79,113,224,232,
		178,185,112,104,218,246,97,228,251,
		34,242,193,238,210,144,12,191,179,
		162,241,81,51,145,235,249,14,239,
		107,49,192,214,31,181,199,106,157,
		184,84,204,176,115,121,50,45,127,4,
		150,254,138,236,205,93,222,114,67,29,
		24,72,243,141,128,195,78,66,215,61,
		156,180, 151,160,137,91,90,15,131,13,
		201,95,96,53,194,233,7,225,140,36,
		103,30,69,142,8,99,37,240,21,10,23,
		190,6,148,247,120,234,75,0,26,197,
		62,94,252,219,203,117,35,11,32,57,
		177,33,88,237,149,56,87,174,20,125,
		136,171,168,68,175,74,165,71,134,139,
		48,27,166,77,146,158,231,83,111,229,
		122,60,211,133,230,220,105,92,41,55,
		46,245,40,244,102,143,54,65,25,63,
		161,1,216,80,73,209,76,132,187,208,
		89,18,169,200,196,135,130,116,188,
		159,86,164,100,109,198,173,186,3,64,
		52,217,226,250,124,123,5,202,38,147,
		118,126,255,82,85,212,207,206,59,
		227,47,16,58,17,182,189,28,42,223,
		183,170,213,119,248,152,2,44,154,
		163,70,221,153,101,155,167,43,172,9,
		129,22,39,253,19,98,108,110,79,113,
		224,232,178,185,112,104,218,246,97,
		228,251,34,242,193,238,210,144,12,
		191,179,162,241,81,51,145,235,249,
		14,239,107,49,192,214,31,181,199,
		106,157,184,84,204,176,115,121,50,
		45,127,4,150,254,138,236,205,93,
		222,114,67,29,24,72,243,141,128,
		195,78,66,215,61,156,180
	];

	var octaves: Int;

	var aOctFreq: Array<Float>; // frequency per octave
	var aOctPers: Array<Float>; // persistence per octave
	var fPersMax: Float; // 1 / max persistence
	
	var iRepeatX: Int;
	var iRepeatY: Int;
	var iRepeatZ: Int;

	var iXoffset: Float;
	var iYoffset: Float;
	var iZoffset: Float;

	var baseFactorX: Float;
	var baseFactorY: Float;
	var baseFactorZ: Float;

	public function new (?baseX: Float, ?baseY: Float, ?baseZ: Float, ?seed, ?octaves, ?falloff) 
	{
		if (baseX == null || baseX == 0) baseX = 64;
		if (baseY == null || baseY == 0) baseY = 64;
		if (baseZ == null || baseZ == 0) baseZ = 64;
		if (seed == null) seed = 123;
		if (falloff == null) falloff = .5;
		this.octaves = if (octaves == null) 4 else octaves;
		baseFactorX = 1 / baseX;
		baseFactorY = 1 / baseY;
		baseFactorZ = 1 / baseZ;
		seedOffset (seed);
		octFreqPers (falloff);
	}
	
	private function calcPixel (_x: Float, _y: Float, _z: Float, px: Int, py: Int): Float
	{
		var fFreq, fPers, x, y, z, xf, yf, zf, X, Y, Z, u, v, w, A, AA, AB, B, BA, BB, x1, y1, z1, hash, g1, g2, g3, g4, g5, g6, g7, g8;
		
		var p = P;
        var s = 0.;
		
        for (i in 0...octaves)
        {
			fFreq = aOctFreq[i];
			fPers = aOctPers[i];

			x = _x * fFreq;
			y = _y * fFreq;
			z = _z * fFreq;

			xf = x - (x % 1);
			yf = y - (y % 1);
			zf = z - (z % 1);

			X = Std.int (xf) & 255;
			Y = Std.int (yf) & 255;
			Z = Std.int (zf) & 255;

			x -= xf;
			y -= yf;
			z -= zf;

			u = x * x * x * (x * (x * 6 - 15) + 10);
			v = y * y * y * (y * (y * 6 - 15) + 10);
			w = z * z * z * (z * (z * 6 - 15) + 10);

/*
			A = (p[X]) + Y;
			AA = (p[A]) + Z;
			AB = (p[A + 1]) + Z;
			B = (p[X + 1]) + Y;
			BA = (p[B]) + Z;
			BB = (p[B + 1]) + Z;
*/
			
			var mx: Int = iRepeatX << (i);
			var my: Int = iRepeatY << (i);
			var mz: Int = iRepeatZ << (i);

			A  = (p[X % mx]) + Y;
			AA = (p[A % my]) + Z;
			AB = (p[(A + 1) % my]) + Z;
			B  = (p[(X + 1) % mx]) + Y;
			BA = (p[B % my]) + Z;
			BB = (p[(B + 1) % my]) + Z;
			
			x1 = x - 1;
			y1 = y - 1;
			z1 = z - 1;
		  
			hash = (p[(BB+1) % mz]) & 15;
			//hash = (p[BB + 1]) & 15;
			g1 = ((hash & 1) == 0 ? (hash < 8 ? x1 : y1) : (hash < 8 ? -x1 : -y1)) + ((hash & 2) == 0 ? hash < 4 ? y1 : (hash == 12 ? x1 : z1) : hash < 4 ? -y1 : (hash == 14 ? -x1 : -z1));
			
			hash = (p[(AB+1) % mz]) & 15;
			//hash = (p[AB + 1]) & 15;
			g2 = ((hash & 1) == 0 ? (hash < 8 ? x  : y1) : (hash < 8 ? -x  : -y1)) + ((hash & 2) == 0 ? hash < 4 ? y1 : (hash == 12 ? x  : z1) : hash < 4 ? -y1 : (hash == 14 ? -x : -z1));
			
			hash = (p[(BA+1) % mz]) & 15;
			//hash = (p[BA + 1]) & 15;
			g3 = ((hash & 1) == 0 ? (hash < 8 ? x1 : y ) : (hash < 8 ? -x1 : -y )) + ((hash & 2) == 0 ? hash < 4 ? y  : (hash == 12 ? x1 : z1) : hash < 4 ? -y  : (hash == 14 ? -x1 : -z1));
			
			hash = (p[(AA+1) % mz]) & 15;
			//hash = (p[AA+1]) & 15;
			g4 = ((hash & 1) == 0 ? (hash < 8 ? x  : y ) : (hash < 8 ? -x  : -y )) + ((hash & 2) == 0 ? hash < 4 ? y  : (hash == 12 ? x  : z1) : hash < 4 ? -y  : (hash == 14 ? -x  : -z1));
			
			hash = (p[BB % mz]) & 15;
			//hash = (p[BB]) & 15;
			g5 = ((hash & 1) == 0 ? (hash < 8 ? x1 : y1) : (hash < 8 ? -x1 : -y1)) + ((hash & 2) == 0 ? hash < 4 ? y1 : (hash == 12 ? x1 : z) : hash < 4 ? -y1 : (hash == 14 ? -x1 : -z));
			
			hash = (p[AB % mz]) & 15;
			//hash = (p[AB]) & 15;
			g6 = ((hash & 1) == 0 ? (hash < 8 ? x  : y1) : (hash < 8 ? -x  : -y1)) + ((hash & 2) == 0 ? hash < 4 ? y1 : (hash == 12 ? x  : z) : hash < 4 ? -y1 : (hash == 14 ? -x  : -z));
			
			hash = (p[BA % mz]) & 15;
			//hash =(p[BA]) & 15;
			g7 = ((hash & 1) == 0 ? (hash < 8 ? x1 : y ) : (hash < 8 ? -x1 : -y )) + ((hash & 2) == 0 ? hash < 4 ? y  : (hash == 12 ? x1 : z) : hash < 4 ? -y  : (hash == 14 ? -x1 : -z));
			
			hash = (p[AA % mz]) & 15;
			//hash = (p[AA]) & 15;
			g8 = ((hash & 1) == 0 ? (hash < 8 ? x  : y ) : (hash < 8 ? -x  : -y )) + ((hash & 2) == 0 ? hash < 4 ? y  : (hash == 12 ? x  : z) : hash < 4 ? -y  : (hash == 14 ? -x  : -z));
			
			g2 += u * (g1 - g2);
			g4 += u * (g3 - g4);
			g6 += u * (g5 - g6);
			g8 += u * (g7 - g8);
			
			g4 += v * (g2 - g4);
			g8 += v * (g6 - g8);
			
			s += (g8 + w * (g4 - g8)) * fPers;
			
		  //if (px + py == 0) trace(s);
        }
		return s;
	}

	private function mix (x: Float, y: Float, a: Float)
	{
		return (1 - a) * x + a * y;
	}
	
	private function isPowerOf2 (x: Int): Bool
	{
		return x != 0 && (x & (x - 1)) == 0;
	}
	
	public function fill (bitmap: BitmapData, _x: Float, _y: Float, _z: Float, stitched: Bool, fractalNoise: Bool = true, channels: Int = 7, greyscale: Bool = false, ?repeatX: Int, ?repeatY: Int, ?repeatZ: Int)
	{
		if (bitmap == null)
			return;
			
		var width: Int = bitmap.width;
		var height: Int = bitmap.height;
		
		//repeatX = Std.int (1 / baseFactorX);
		//repeatY = Std.int (1 / baseFactorY);
		//repeatZ = Std.int (1 / baseFactorZ);
		
		repeatX = (repeatX == null)? width : repeatX;
		repeatY = (repeatY == null)? height : repeatY;
		repeatZ = (repeatZ == null)? 256 : repeatZ;
		
		iRepeatX = Std.int (baseFactorX * repeatX);
		iRepeatY = Std.int (baseFactorY * repeatY);
		iRepeatZ = Std.int (baseFactorZ * repeatZ);
		
		//trace(iRepeatX + "  "  + repeatX);
		//trace(iRepeatY + "  "  + repeatY);
		
		var fastStitch: Bool = isPowerOf2 (repeatX) && (iRepeatX >= 1) && isPowerOf2 (repeatY) && (iRepeatX >= 1) && isPowerOf2 (repeatZ) && (iRepeatX >= 1);
		if (!fastStitch || !stitched)
		{
			iRepeatX = 0x200;
			iRepeatY = 0x200;
			iRepeatZ = 0x200;
		}
		
		//trace(fastStitch);
		
		var baseX: Float = _x * baseFactorX + iXoffset;
		_y = _y * baseFactorY + iYoffset;
		_z = _z * baseFactorZ + iZoffset;

		var baseWidth = baseFactorX * width;
		var baseHeight = baseFactorY * height;

		var octaves = octaves;
		var aOctFreq = aOctFreq;
		var aOctPers = aOctPers;
		
		fastStitch = false;
		for (py in 0...height)
		{
			_x = baseX;

			for (px in 0...width)
			{
				var s: Float;
				var b: Int;
				
				var ch = channels;
				if (greyscale)
					ch = 8 + 1 + ((8 + 1) << 4);

				var color: Int = 0;
				for (k in 0...4)
				{
					color = color << 8;
					if (ch & 1 == 1)
					{
						if (stitched && !fastStitch)
						{
							var s1 = calcPixel (_x, _y, _z + k, px, py);
							var s2 = calcPixel (_x - baseWidth, _y, _z + k, px, py);
							var s3 = calcPixel (_x, _y - baseHeight, _z + k, px, py);
							var s4 = calcPixel (_x - baseWidth, _y - baseHeight, _z + k, px, py);
							s = mix (mix (s1, s2, px / width), mix (s3, s4, px / width), py / height);
						}
						else
							s = calcPixel (_x, _y, _z, px, py);
						
						//if (s < -1) s = -1; else if (s > 1) s = 1;
							
						if (!fractalNoise)
						{
							if (s < 0) s = -s;
							s = (s - 1) / fPersMax;
						}
						
						b = Std.int ((s * fPersMax + 1) * 128);
						//if (px + py == 0) trace(b);
						//if (b > 255) b = 255; else if (b < 0) b = 0;
						color += b & 0xFF;
					}
					ch = ch >> 1;
					
					P.push (P.shift ());
				}
				
				var argb = 0xFF000000;
				if (channels & 8 != 0)
					argb = (color & 0xFF) << 24;
				color = (color >> 8) & 0xFFFFFF;
				
				if (greyscale)
				{
					color &= 0xFF0000;
					color = color | (color >> 8) | (color >> 16);
				}
				//if (px + py == 0) trace(color);
				bitmap.setPixel32 (px, py, argb | color);
				
				P.unshift (P.pop ());
				P.unshift (P.pop ());
				P.unshift (P.pop ());
				P.unshift (P.pop ());
				
				
				_x += baseFactorX;
			}
			_y += baseFactorY;
		}
	}
	

	function octFreqPers (fPersistence)
	{
		var fFreq: Float, fPers: Float;

		aOctFreq = [];
		aOctPers = [];
		fPersMax = 0;

		for (i in 0...octaves) 
		{
			fFreq = Math.pow (2, i);
			fPers = Math.pow (fPersistence, i);
			fPersMax += fPers;
			aOctFreq.push (fFreq);
			aOctPers.push (fPers);
		}

		fPersMax = 1 / fPersMax;
	}

	function seedOffset (iSeed : Int) 
	{
		iXoffset = iSeed = Std.int ((iSeed * 16807.) % 2147483647);
		iYoffset = iSeed = Std.int ((iSeed * 16807.) % 2147483647);
		iZoffset = iSeed = Std.int ((iSeed * 16807.) % 2147483647);
	}
}