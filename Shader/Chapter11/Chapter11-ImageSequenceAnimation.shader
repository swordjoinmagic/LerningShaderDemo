// 序列帧动画
Shader "Unity Shaders Book/Chapter 11/ImageSequenceAnimation" {
    Properties {
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        _MainTex("Image Sequence",2D) = "white" {}
        // 水平方向上有多少帧关键帧
        _HorizontalAmount("Horizontal Amount",Float) = 4
        // 竖直方向上有多少帧关键帧
        _VerticallAmount("Vertical Amount",Float) = 4
        // 动画播放速度
        _Speed("Speed",Range(1,100)) = 30
    }
    SubShader {
        Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType"="Transparent" }

        Pass {
            Tags{ "LightMode" = "ForwardBase" }

            ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                float _HorizontalAmount;
                float _VerticallAmount;
                float _Speed;

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
                    o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{

                    // 获得整数时间
                    float time = floor(_Time.y * _Speed) % (_HorizontalAmount*_VerticallAmount);

                    // 根据时间计算当前行数和列数
                    float row = floor(time/_HorizontalAmount);
                    float column = time - row * _HorizontalAmount;

                    // 对uv坐标进行偏移
                    half2 uv = float2(i.uv.x/_HorizontalAmount,i.uv.y/_VerticallAmount);
                    uv.x += column / _HorizontalAmount;
                    uv.y -= row / _VerticallAmount;

                    fixed4 c = tex2D(_MainTex,uv);
                    c.rgb *= _Color;

                    // fixed4 c = fixed4(col/10,0,0,1.0);

                    return c;
                }

            ENDCG
        }

    }
    FallBack "Diffuse"
    
}