Shader "Unity Shaders Book/Chapter 11/ScrollingBackground" {
    Properties {
        // 第一层纹理(较远)
        _MainTex("Base Layer (RGB)",2D) = "white" {}
        // 第二层纹理(较近)
        _DetailTex("2nd Layer (RGB)",2D) = "white" {}
        // 表示第一层纹理水平滚动速度
        _ScrollX("Base layer Scroll Speed",Float) = 1.0
        // 表示第二层纹理水平滚动速度
        _Scroll2X("2nd Layer (RGB)",Float) = 1
        // 用于控制纹理的整体亮度
        _Multiplier ("Layer Multiplier", Float) = 1
    }
    SubShader {
        Tags { "RenderType" = "Opaque" "Queue"="Geometry" }
        Pass {
            Tags{ "LightMode" = "ForwardBase" }
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _DetailTex;
                float4 _DetailTex_ST;
                float _ScrollX;
                float _Scroll2X;
                float _Multiplier;

                struct a2v{
                    float4 vertex : POSITION;
                    float2 texcoord : TEXCOORD0;
                };
                struct v2f{
                    float4 pos : SV_POSITION;
                    float4 uv : TEXCOORD0;
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);

                    // frc表示返回每个矢量部分的小数部分,比如对于(12.3,99.1),返回(0.3,0.1)
                    o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex) + frac( float2(_ScrollX,0.0) * _Time.y );
                    o.uv.zw = TRANSFORM_TEX(v.texcoord,_DetailTex) + frac( float2(_Scroll2X,0.0) * _Time.y);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed4 firstLayer = tex2D(_MainTex,i.uv.xy);
                    fixed4 secondLayer = tex2D(_DetailTex,i.uv.zw);

                    fixed4 c = lerp(firstLayer,secondLayer,secondLayer.a);
                    // fixed4 c = firstLayer*secondLayer;


                    c.rgb *= _Multiplier;

                    return c;
                }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}