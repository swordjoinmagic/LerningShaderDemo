Shader "Unity Shaders Book/Chapter 10/Mirror" {
    Properties {
        _MainTex("_Main Tex",2D) = "white" {}
    }
    SubShader {

        Tags{ "RenderType" = "Opaque"}

        Pass {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
                #pragma mutli_compile_fwbase

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                sampler2D _MainTex;
                float4 _MainTex_ST;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    float2 uv : TEXCOORD0;
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = v.texcoord;

                    o.uv.x = 1-o.uv.x;

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    return tex2D(_MainTex,i.uv);
                }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}