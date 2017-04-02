//include this before other shader code:

//NOTES:
//desktop GLSL version 1.20 is similar to GLSL ES version 1.00 according to:
//http://stackoverflow.com/questions/10383113/differences-between-glsl-and-glsl-es-2
//example desktop preamble:
//#version 120
//#define lowp
//#define mediump
//#define highp
//example ES GLSL 1.00 preamble:
//#version 100 //must be first line
//Shaders that do not include a #version directive will be treated as targeting version 1.10.
// Shaders that specify #version 100 will be treated as targeting version 1.00 of the OpenGL ES Shading Language

//https://www.khronos.org/opengl/wiki/Detecting_the_Shader_Model
//OpenGL Version 	GLSL Version
//2.0 	1.10
//2.1 	1.20    ~= GLSL ES 1.0
//3.0 	1.30
//3.1 	1.40
//3.2 	1.50

//GLSL 1.2: https://www.opengl.org/registry/doc/GLSLangSpec.Full.1.20.8.pdf
//passing data: http://stackoverflow.com/questions/7954927/glsl-passing-a-list-of-values-to-fragment-shader
//built-in vars: http://www.shaderific.com/glsl-variables/
//https://www.khronos.org/opengl/wiki/Built-in_Variable_(GLSL)
//https://www.opengl.org/discussion_boards/showthread.php/182248-understanding-gl_PointCoord-(always-0)
//http://webglfactory.blogspot.com/2011/05/how-to-convert-world-to-screen.html
//http://stackoverflow.com/questions/7317119/how-to-achieve-glorthof-in-opengl-es-2-0

//Never ever branch in the fs if not absolutely avoidable.  Even on the most modern hardware fragments are evaluated in blocks of 4 and all branches that are taken in any of them forces the gpu to evaluate them for every fragment regardless of whether needed or not.
//To avoid branches one should always use functions like mix, step, smoothstep, etc.


//broken   #version 130 //bit-wise ops require GLSL 1.3 to be enabled
//nice analysis of precision: http://litherum.blogspot.com/2013/04/precision-qualifiers-in-opengl-es.html
#ifdef GL_ES
   #version 100 //GLSL ES 1.0 ~= GLSL 1.2
   #define lowp //10-bit float
   #define mediump //16-bit float: 1 sign + 5 exp + 10 mantissa
   #define highp //32-bit float: 1 sign + 8 exp + 23 mantissa
//   precision mediump float;
   #define PRECISION(stmt)  stmt;
#else
   #version 120 //gl_PointCoord requires GLSL 1.2 to be enabled
   #define PRECISION(stmt)
#endif
PRECISION(mediump float)

//compensate for floating point precision:
const float FUD = 1.0e-6;
//#define NOT(expr)  (1.0 - BOOL(expr))
#define BOOL(value)  float(value) //convert bool expr to 0/1
#define EQ(lhs, rhs)  (abs((lhs) - (rhs)) < FUD)
#define NE(lhs, rhs)  (abs((lhs) - (rhs)) >= FUD)
//#define EQ3f(lhs, rhs)  lessThan(abs((lhs) - (rhs)), vec3(FUD))
//#define GE(lhs, rhs)  step(rhs - FUD, lhs) //convert lhs >= rhs to 0/1
//#define GT(lhs, rhs)  step(lhs + FUD, lhs)
//#define LE(lhs, rhs)  step(lhs + FUD, rhs)
//#define LT(lhs, rhs)  step(lhs - FUD, rhs)
#define GE(lhs, rhs)  ((lhs) >= (rhs) - FUD)
#define GT(lhs, rhs)  ((lhs) > (rhs) + FUD)
#define LE(lhs, rhs)  ((lhs) <= (rhs) + FUD)
#define LT(lhs, rhs)  ((lhs) < (rhs) - FUD)

//force val to be non-0:
//#define is0(val)  vec3(equal(val, vec3(0.0)))
//#define NZ(val)  (val + is0(val))
//#define isnon0(val)  notEqual(val, vec3(0.0))

//try to avoid conditional branches:
//NOTE: bit-wise ops require GLSL 1.3
//#define IIF(expr, true, false)  ((expr) & (true) | ~(expr) & (false))
#define IIF(expr, true, false)  mix(false, true, BOOL(expr))

//compensate for lack of bit-wise ops:
//bit-wise ops require GLSL 1.3 to be enabled; not available on RPi
//NOTE: RPi (GL ES 1.2) doesn't support ivec, uvec :(
//CAUTION: use functions if nested macros not being expanded
//#define VEC3(val)  vec3(float(val), float(val), float(val)) //NOTE: shaderific says vec ctor will do this
//#define SELECT1of3(which)  vec3(int(which) == 0, int(which) == 1, int(which) == 2)
//#define SELECT1of3(which)  IIF(equal(VEC3(which), vec3(0.0, 1.0, 2.0)), VEC3(1), VEC3(1e30))
#define SELECT1of3(which)  vec3(equal(vec3(float(which)), vec3(0.0, 1.0, 2.0))) //, VEC3(1), VEC3(1e30))
//#define VEC4(val)  vec4(float(val), float(val), float(val), float(val))
//#define SELECT1of4(which)  vec4(int(which) == 0, int(which) == 1, int(which) == 2, int(which) == 3)
//#define VEC3tag(val)  vec4(float(val), float(val), float(val), 1.0)
//#define SELECT3tag(which)  vec4(int(which) == 0, int(which) == 1, int(which) == 2, float(which))
//#define WHICH(val4)  sign(val4) * vec4(8.0, 4.0, 2.0, 1.0) //assumes non-negative
//#define WHICH(n)  floor(float(n) / 8.0)
//#define DBYTEOF(val, byte)  (IIF(byte == 0.0, val.r, ZERO.r) + IIF(byte == 1.0, val.g, ZERO.g) + IIF(byte == 2.0, val.b, ZERO.b))
//#define DBYTETO(val, byte)  vec4(IIF(byte == 0.0, val, 0.0), IIF(byte == 1.0, val, 0.0), IIF(byte == 2.0, val, 0.0), 0.0)

//#define MASK(n)  pow(2.0, 23.0 - n)
//#define IFBIT(val, n)  LSB(floor(n / MASK(n)))
//#define LSB(val)  (floor((val) / 2.0) != (val) / 2.0)
//const vec4 ZERO = VEC4(0); //vec4(0.0, 0.0, 0.0, 0.0);
//#define SHL(val, bits)  (val * pow(2.0, float(bits)))
//#define SHR(val, bits)  (val / pow(2.0, float(bits)))
//#define AND(val, bitmask)  (mod(val, 2.0 * bitmask) >= bitmask)
//#define AND(val4, mask3tag)  (mod(val4, 2.0 * mask4 * select4) >= mask4 * select4)
//#define ANDIF3f(val, mask)  vec3(greaterThanEqual(mod(val, 2.0 * mask), mask)) //div by 0 = infinity according to http://stackoverflow.com/questions/16069959/glsl-how-to-ensure-largest-possible-float-value-without-overflow
//AND:
//do bit-wise AND component by compoent
//div by 0 = infinity with no arith error? according to http://stackoverflow.com/questions/16069959/glsl-how-to-ensure-largest-possible-float-value-without-overflow
//however, 0 terms must result in 0, so add extra NZ condition to avoid that
const float FLOAT2BITS = 255.0 / 256.0; //convert 1.0 <-> 1/2 + 1/4 + 1/8 + 1/16 + 1/32 + 1/64 + 1/128 + 1/256 so bit-wise AND will work
//#define AND3f(val, mask)  (vec3(greaterThanEqual(mod(min(val, RGB_BITS), 2.0 * mask), mask)) * sign(mask))
//#define AND3f(val, mask)  (vec3(greaterThanEqual(mod(val * FLOAT2BITS, 2.0 * NZ(mask)), NZ(mask))) * sign(mask) / FLOAT2BITS)
#define AND3(val, mask)  dot(vec3(greaterThanEqual(mod(val * FLOAT2BITS, 2.0 * mask), mask)), sign(mask)) //strip off extraneous results for mask components of 0

//create a normalized vec4 bit mask:
//msb = bit 0, lsb = bit 23
#define MASK3f(n)  (pow(0.5, mod(float(n), 8.0) + 1.0) * SELECT1of3(floor(float(n) / 8.0)))
//#define MASK3f_tag(n)  vec4(MASK3F(n), WHICH(n))
//#define MASK4f(n)  DBYTETO(pow(0.5, mod(float(n), 8.0) + 1.0), floor(float(n) / 8.0))
//#define MASK3tag(n)  vec4(MASK3f(n), floor(float(n) / 8.0)) //(VEC3tag(pow(0.5, mod(float(n), 8.0) + 1.0)) * SELECT3tag(floor(float(n) / 8.0)))

//#define MASK4i(n) MASK4f(float(n))
//vec4 MASK4f(float n)
//{
//    float byte = floor(n / 8.0), bit = pow(0.5, mod(n, 8.0) + 1.0); //pow(2.0, 7.0 - mod(n, 8.0));
//    return vec4(IIF(byte == 0.0, bit, 0.0), IIF(byte == 1.0, bit, 0.0), IIF(byte == 2.0, bit, 0.0), 1.0);
////    return pow(2.0, 23.0 - n);
//}
//val is normalized [0..1] .rgba
//bool IFBIT(vec4 val, float n)
//{
//    float byte = floor(n / 8.0), bit = pow(2.0, 7.0 - mod(n, 8.0));
//    return (mod(256.0 * (IIF(byte == 0.0, val.r, 0.0) + IIF(byte == 1.0, val.g, 0.0) + IIF(byte == 2.0, val.b, 0.0)), 2.0 * bit) >= bit);
////    return LSB(floor(BYTEOF(val, byte) / bit));
//}

#if 0
//CAUTION: mediump is only 16 bits
#define MASK(bit)  pow(2.0, 23.0 - bit)
bool IFBIT(float val, int bit)
{
	float mask = MASK(bit);
	return mod(val, 2.0 * mask) >= mask; //trim upper bits, check target bit
or
	return fract(floor(val / mask) / 2.0) != 0.0;
}
#endif

const float PI = 3.1415926535897932384626433832795;

//dimensions of nodes on screen:
//"??" are filled in by caller
//const float VGROUP = float(??);
const float SCR_WIDTH = float(??);
const float SCR_HEIGHT = float(??);
const float NUM_UNIV = float(??);
const float UNIV_LEN = float(??); //SCR_HEIGHT; // / VGROUP; //float(??);
const float NODEBIT_WIDTH = float(SCR_WIDTH / NUM_UNIV);
const float NODE_HEIGHT = float(SCR_HEIGHT / UNIV_LEN);
//#define PTSIZE  max(NODEBIT_WIDTH, NODE_HEIGHT)
const float PTSIZE = max(NODEBIT_WIDTH, NODE_HEIGHT);
const float MAX_UNIV = NUM_UNIV - 1.0;
const float UNIV_MAX = UNIV_LEN - 1.0;

//caller options:
//#define WS281X_FMT
//#define PROGRESS_BAR

//primary RGBA colors:
const vec4 RED = vec4(1.0, 0.0, 0.0, 1.0);
const vec4 GREEN = vec4(0.0, 1.0, 0.0, 1.0);
const vec4 BLUE = vec4(0.0, 0.0, 1.0, 1.0);
const vec4 YELLOW = vec4(1.0, 1.0, 0.0, 1.0);
const vec4 CYAN = vec4(0.0, 1.0, 1.0, 1.0);
const vec4 MAGENTA = vec4(1.0, 0.0, 1.0, 1.0);
#define gray(val)  vec4(val, val, val, 1.0)
const vec4 WHITE = gray(1.0); //vec4(1.0, 1.0, 1.0, 1.0);
const vec4 BLACK = gray(0.0); //vec4(0.0, 0.0, 0.0, 1.0);
//const vec4 GPUFX = vec4(0.0, 0.0, 0.0, 0.0); //tranparent texture color allowing GPU fx to show thru

//from http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl:
vec3 rgb2hsv(vec3 c)
{
//    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
//    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
//    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    vec4 K = vec4(0.0, -1.0, 2.0, -3.0) / 3.0; //TODO: make const?
//    vec4 p = IIF(GE(c.g, c.b), vec4(c.gb, K.xy), vec4(c.bg, K.wz));
//    vec4 q = IIF(GE(c.r, p.x), vec4(c.r, p.yzx), vec4(p.xyw, c.r));
    vec4 p = IIF(greaterThanEqual(c.g, c.b), vec4(c.gb, K.xy), vec4(c.bg, K.wz));
    vec4 q = IIF(greaterThanEqual(c.r, p.x), vec4(c.r, p.yzx), vec4(p.xyw, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
//    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec4 K = vec4(3.0, 2.0, 1.0, 9.0) / 3.0; //TODO: make const?
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

//eof
