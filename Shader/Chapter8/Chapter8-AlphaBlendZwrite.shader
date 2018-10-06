Shader "Unity Shaders Book/Chapter 8/AlphaBlendZwrite" {
    Properties {
        _Color("Color",Color) = (1, 1, 1, 1)
        _MainTex("Main Tex",2D) = "white" {}
        _AlphaScale("Alpha Scale",Range(0,1.0)) = 1
    }
    SubShader {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }

        // 开启深度渲染的Pass,用于记录透明物体内部各个物体之间的深度关系
        Pass {
            ZWrite On

            // ColorMask 0 表示该Pass不会写入任何颜色通道
            ColorMask 0
        }

        // 关闭深入写入的Pass,用于渲染透明度混合的关系
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                float _AlphaScale;

                struct a2v{
                    float4 vertex : POSITION; 
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    float3 worldPos : TEXCOORD0;
                    float3 worldNormal : TEXCOORD1;
                    float2 uv : TEXCOORD2;
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldNormal = UnityObjectToWorldNormal(v.vertex);
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                    o.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed3 worldNormal = normalize(i.worldNormal);
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                    fixed4 texColor = tex2D(_MainTex,i.uv);

                    fixed3 albedo = texColor.rgb * _Color.rgb;

                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldLightDir,worldNormal));

                    return fixed4(diffuse+ambient,texColor.a * _AlphaScale);
                }
            ENDCG
        }
    }
    FallBack "Diffuse"
    
}