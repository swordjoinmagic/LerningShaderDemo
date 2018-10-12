Shader "Unity Shaders Book/Chapter 11/Water" {
    Properties {
        // 河流纹理
        _MainTex("Main Tex",2D) = "white" {}
        // 控制整体颜色
        _Color("Color Tine",Color) = (1, 1, 1, 1)
        // 用于控制水流播放东的幅度
        _Magnitude("Distortion Magnitude",Float) = 1
        // 用于控制波动pinlv
        _Frequency("Distortion Frequency",Float) = 1
        // 用于控制波长的倒数
        _InvWaveLength("Distortion Inverse Wave Length",Float) = 10
        // 用于控制河流纹理的移动速度
        _Speed("Speed",Float) = 0.5
    }
    SubShader {
        Tags { "RenderType" = "Transparent" "IgnoreProjector" = "True" "Queue" = "Transparent" "DisableBatching"="True" }
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed4 _Color;
                float _Magnitude;
                float _Frequency;
                float _InvWaveLength;
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
                    
                    float4 offset;

                    offset.yzw = float3(0,0,0);

                    // 只对顶点的x方向进行偏移
                    offset.x = sin(_Frequency*_Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;

                    // 顶点偏移
                    o.pos = UnityObjectToClipPos(v.vertex + offset);

                    o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                    o.uv += float2(0.0, _Time.y * _Speed);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed4 c = tex2D(_MainTex,i.uv);
                    c.rgb *= _Color.rgb;
                    return c;
                }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}