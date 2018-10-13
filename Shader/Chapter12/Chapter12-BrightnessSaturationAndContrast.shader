Shader "Unity Shaders Book/Chapter 11/BrightnessSaturationAndContrast" {
    Properties {
        _MainTex("Main Tex",2D) = "white" {}
        _Brightness("Brightness",Float) = 1
        _Saturation("Saturation",Float) = 1
        _Contrast("Contrast",Float) = 1
    }
    SubShader {
        ZTest Always
        Cull Off
        ZWrite Off

        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue"="Transparent" }

        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                sampler2D _MainTex;
                float4 _MainTex_ST;
                float _Brightness;
                float _Saturation;
                float _Contrast;

                struct a2v{
                    float4 vertex : POSITION;
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
                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    // 对屏幕图像(贴图)进行采样
                    fixed4 renderTex = tex2D(_MainTex,i.uv);
                    // 调整亮度
                    fixed3 finalColor = renderTex.rgb * _Brightness;

                    // 调整饱和度
                    fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                    fixed3 luminanceColor = fixed3(luminance,luminance,luminance);
                    finalColor = lerp(luminanceColor,finalColor,_Saturation);

                    // 调整对比度
                    fixed3 avgColor = fixed3(0.5,0.5,0.5);
                    finalColor = lerp(avgColor,finalColor,_Contrast);

                    return fixed4(finalColor,renderTex.a);
                }
            ENDCG
        }
    }
    FallBack Off
    
}