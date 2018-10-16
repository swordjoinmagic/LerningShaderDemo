Shader "sjmShaderDemonTest/PassTest1" {
    Properties {
        
    }
    SubShader {
        Pass {
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                struct a2v{
                    float4 vertex : POSITION;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    return fixed4(1,0,0,0);
                }
            ENDCG
        }
        Pass{
            Blend One One
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                struct a2v{
                    float4 vertex : POSITION;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    return fixed4(1,0,0.4,0);
                }
            ENDCG
        }
    }
    FallBack "Diffuse"
    
}