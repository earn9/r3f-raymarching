uniform float time;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPosition;
// https://gist.github.com/yiwenl/3f804e80d0930e34a0b33359259b556c
mat4 rotationMatrix(vec3 axis, float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;
  
  return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
              oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
              oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
              0.0,                                0.0,                                0.0,                                1.0);
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
  mat4 m = rotationMatrix(axis, angle);
  return (m * vec4(v, 1.0)).xyz;
}

// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere(vec3 p, float radius) {
  return length(p) - radius;
}

float SineCrazy(vec3 p) {
  return 1. - (sin(p.x) + sin(p.y) + sin(p.z)) / 3.; 
}

float sdOctahedron( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }

float opUnion( float d1, float d2 ) { return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }


float scene(vec3 p) {

  vec3 p1 = rotate(p, vec3(1.,0.,0.), time * 6.283185);
  vec3 p2 = rotate(p, vec3(1.), -time * 6.283185);
  
  float scale  = 12.;

  float minO = max(
    sdSphere(p, .4),
    sdBox(p2, vec3(.3))
  );

  float sinecc = (0.86 - SineCrazy((p2 + vec3(0., .2, 0.)) * scale)) / scale;

  float deformedSphere = max(
    sdOctahedron(p1, .3),
    sinecc
  );

  float frame = opSubtraction(
    sdSphere(p, .4),
    minO
  );

  return min(frame, sdOctahedron(p1, .3)); 
}

// get normal for each point in the scene
vec3 getNormal(vec3 p){
	
	vec2 o = vec2(0.001,0.);
	// 0.001,0,0
	return normalize(
		vec3(
			scene(p + o.xyy) - scene(p - o.xyy),
			scene(p + o.yxy) - scene(p - o.yxy),
			scene(p + o.yyx) - scene(p - o.yyx)
		)
	);
}

vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 getColor(float amount) {
  vec3 color = 0.5 + .5 * cos(6.28319 * (vec3(0.2, 0.,0.) + amount * vec3(1., 1., 0.5)));

  return color * amount;
}

vec3 getColorAmount(vec3 p) {
  float amount = clamp((1.5 - length(p))/2., 0., 1.);
  vec3 color = 0.5 + .5 * cos(6.28319 * (vec3(0.2, 0.,0.) + amount * vec3(1., 1., 0.5)));

  return color * amount;

}

void main()	{
    vec2 uv = vUv;
  
    vec3 camPos = vec3(0, 0, 2.);
    vec2 p = uv - vec2(0.5);
    vec3 ray = normalize(vec3(p, -1.));
    vec3 rayPos = camPos;
    float curDist = 0.;
    // from camera to point
    float rayLength = 0.;
    vec3 color = vec3(0.);
    vec3 light = vec3(1.,1.,1.);
    for (int i = 0; i <= 128; i++) {
      curDist = scene(rayPos);
      rayLength +=  0.6 * curDist;
      rayPos = camPos + ray * rayLength;
      // if hitting the object
      if (abs(curDist) < 0.001) {

        vec3 n = getNormal(rayPos);

        float diff = dot(n, light);

        // color = getColor(3. * length((rayPos)));

        break;
      }

      color += 0.02 * getColorAmount(rayPos);
    }
    gl_FragColor = vec4(color, 1.);
}
