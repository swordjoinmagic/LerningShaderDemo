// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// 透明度测试Shader
Shader "Unity Shaders Book/Chapter 8/AlphaTest" {
    Properties {
        _MainTex("Main Tex",2D) = "white" {}
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 在透明度测试时使用阈值,
        // 当目标像素透明度低于该属性时,
        // 舍弃该片元
        _Cutoff("Alpha Cutoff",Range(0,1)) = 0.5
    }
    SubShader {
        // 设置渲染队列
        Tags { "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout"}

        Pass{
            Tags{ "LightMode" = "ForwardBase" }

            // 双面渲染
            Cull Off

            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed _Cutoff;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 texcoord : TEXCOORD0;
                };  

                struct v2f{
                    float4 pos : SV_POSITION;
                    float3 worldNormal : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float2 uv : TEXCOORD2;
                };

                v2f vert(a2v v){
                    v2f o;
                    
                    // 顶点变换
                    o.pos = UnityObjectToClipPos(v.vertex);

                    // 获得法线
                    o.worldNormal = UnityObjectToWorldNormal(v.vertex);

                    // 获得世界坐标下的顶点
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                    o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed3 worldNormal = normalize(i.worldNormal);
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                    fixed4 texColor = tex2D(_MainTex,i.uv);

                    clip(texColor.a - _Cutoff);

                    fixed3 albedo = texColor.rgb * _Color.rgb;

                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal,worldLightDir));

                    return fixed4(ambient + diffuse,1.0);

                }

            ENDCG

        }
    }
    FallBack "Diffuse"
    
}