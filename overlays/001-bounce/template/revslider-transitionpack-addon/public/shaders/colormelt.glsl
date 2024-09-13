uniform float progress;
uniform sampler2D src1;
uniform sampler2D src2;
uniform vec4 resolution;

uniform float zoomStrength;
uniform float amo; //Amount of Circles
uniform float sd;  //Seed for rnd. Change For diffrent result
uniform float Cs;   //Size of the Circle    

uniform float rMin;
uniform float rMax;
uniform float gMin;
uniform float gMax;
uniform float bMin;
uniform float bMax;
varying vec2 vUv;
const int passes = 6;
float pi = 3.141592653;


vec4 getFromColor(vec2 uv) {
    return TEXTURE2D(src1, uv);
}
vec4 getToColor(vec2 uv) {
    return TEXTURE2D(src2, uv);
}

float rnd(float n, float seed){
    return sin(cos(n * 5823. * seed) * 3145.);
}

float circle(vec2 pos,float size, vec2 p){
    return smoothstep(0.0,1.0,(size-length(p-pos)));
}

vec3 blur(sampler2D tex,vec2 p, float size, float amp){
        
    vec3 color = vec3(0.0);
    float am = 1.0/pow(size*2.,2.);

    for(float i = -size;i <size;i++){
        for(float j = -size;j <size;j++){
            
            vec2 newp = p + vec2(i,j) * 0.001 * amp;
            color += vec3(texture(tex,newp).xyz);
        }
    }
    
    color *= am;
    
    p += rnd(p.x,p.y)*0.002 * amp;
    
    color += vec3(texture(tex,p).xyz);
    
    return color * 0.5;
    
}

void main(){    

    float speed = 0.5;
    float amo = 15.; //Amount of Circles. Does effect the performance quit a bit.
    float sd = 1.0;  //Seed for rnd. Change For diffrent result
    float Cs = 1.7;   //Size of the Circle
    

    vec2 fragCoord = vUv;
    float iTime = progress*4.;    
    
    vec2 iResolution = vec2(resolution.z, resolution.w); 
    
    
    vec2 p = (fragCoord*2.0-iResolution.xy)/iResolution.y;
    vec2 q;
    vec3 col;
    
    
    float strength = 0.5 * (smoothstep(0.,1.0,4.-iTime));
    
    
    
    vec3 Col1 = vec3(0.7,0.1,0.1); //Assigns a random Color from these 5.
    float tol1 = 0.1; //Changes the possible diffrenses for each Cicles Color
    vec3 Col2 = vec3(0.7,0.1,0.1);
    float tol2 = 0.1;
    vec3 Col3 = vec3(0.1,0.5,0.7);
    float tol3 = 0.1;
    vec3 Col4 = vec3(0.1,0.5,0.7);
    float tol4 = 0.1;
    vec3 Col5 = vec3(0.1,0.5,0.7);
    float tol5 = 0.1;
    vec3[] Colors = vec3[] (Col1,Col2,Col3,Col4,Col5);
    float[] tolerance = float[] (tol1,tol2,tol3,tol4,tol5);
    
    bool DoBackground = false;//Takes the avg of the Background as the Color
    
    bool DirNotRandom = true;//Change the Direction of the Circles to:
    
    vec2 NewDir = vec2(0.,-1.);//This is the new Dir Starting pos is Calculated with it too
    
    float EFCS = 0.5; //Changes the Effekt size/strength of each cicrle based 
                     //on the pixels distanz to the circle center
    
    vec2 colAmpX = vec2(1.); //Making a Strength gredient dosent Work jet...
    
    float t = speed * iTime;
    
    float zoom = 1.0 - sin(smoothstep(0.,3.14159,iTime*.25*3.14159)*3.14159)*zoomStrength;
    
    //Shaking effekt
    q.x = rnd(5.,2. + floor(t) * 0.01) * 0.1;
    q.y = rnd(5.,1. + floor(t) * 0.01) * 0.1;
    
    vec2 dir = normalize(q);
    
    p += dir * sin(fract(t) * 3.14159 * 2.) * pow(sin(fract(t)*3.14159+3.14159),1.) * 0.1 * (20.-zoom * 20.);
    p *= zoom;
    
    //weaking the Transition effekt with Time
    float effSt = sin(smoothstep(0.,1.,iTime*0.25 * speed * 2.)*3.14159);
    
    
    
    
    
    
    //Load image and Bluring it
    col += blur(src2,(p * iResolution.y + iResolution.xy)*0.5/iResolution.xy,10.,3. * effSt) * smoothstep(0.0,1.0,iTime*0.25);
    col += blur(src1,(p * iResolution.y + iResolution.xy)*0.5/iResolution.xy,10.,3. * effSt) * smoothstep(1.0,0.0,iTime*0.25);
    
    //circles
    vec3 CirclCol = vec3(0.); 
    for(float i = 0.;i<amo;i++){
        vec2 cq = vec2(rnd(i*5.32*sd,i*1.42*sd),rnd(i*3.32,i*0.42*sd));
        vec2 Cdir = vec2(rnd(i*0.83*sd,i*0.89*sd),rnd(i*0.51*sd,i*0.82*sd));
        if(DirNotRandom){cq += NewDir * -1.;Cdir = NewDir *(1.5 + 0.4 * rnd(cq.x*0.83*sd,cq.y*0.89*sd));}
        int rnd1 = int(floor((0.5 + 0.5 * rnd(cq.x*1.4*sd,cq.y*1.2*sd)) * 5.) );
        int rnd2 = int(floor((0.5 + 0.5 * rnd(cq.x*1.4*sd,cq.y*1.2*sd)) * 5.) );
        
        vec3 ChosenCol = Colors[rnd1];
        float ChosenTol = tolerance[rnd2];

        float C1 = rnd(cq.x*0.841,cq.y*8.459*sd) * ChosenTol + ChosenCol.x;
        float C2 = rnd(cq.x*4.615,cq.y*2.195*sd) * ChosenTol + ChosenCol.y;
        float C3 = rnd(cq.x*1.517,cq.y*3.315*sd) * ChosenTol + ChosenCol.z;
        
        
        
        float Csize = rnd(cq.x*1.517,cq.y*3.315) * .1 + Cs;
        
        vec3 Rcol = vec3(C1,C2,C3) * .5 * (1. * 12.5/amo);
        
        if(DoBackground == true){
        
            Rcol = blur(src2,cq,4.,0.1) * .5;
        
        }
        
        float s = 20.-iTime*10.;
        float StC = smoothstep(s-3.0,s,i);
        
        cq += Cdir * pow(iTime*0.5,3.0) ;
        cq.x *= 1.2;
        
        CirclCol += 1.*Rcol * circle(cq,Csize,p) * sin(smoothstep(0.,1.,iTime*0.5 * speed + 0.25)*3.14159) * StC * effSt;
        col *= 1.-circle(cq,Csize-0.5,p) * StC * .25;
        //CirclCol *= 0.5 + smoothstep(0.,Csize-0.75,length(p-cq)) * 0.5; remove
        // because it created darker holes at earlyer rendered circles.

    }
    
    col += CirclCol;
    
    gl_FragColor = vec4(col,1.0);
}