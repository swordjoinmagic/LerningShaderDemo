Shader "Unity Shaders Book/Chapter 8/AlphaBlend" {
    Properties {
        // 控制物体整体的颜色
        _Color("Color",Color) = (1, 1, 1, 1)
        // 物体纹理
        _MainTex("Main Tex",2D) = "white" {}
        // 用于控制整体透明度
        _AlphaScale("Alpha Scale",Range(0,1)) = 1

    }
    SubShader {
        //Queue: 设置渲染队列为Transparent的队列
        //RenderType:用来指明该shader是一个使用了透明度混合的Shader
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            // 关闭深度写入
            ZWrite Off
            // 开启颜色混合模式
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
                    float3 worldNormal : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float2 uv : TEXCOORD2;
                };

                v2f vert(a2v v){
                    v2f o;

                    o.pos = UnityObjectToClipPos(v.vertex);

                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                    o.uv =  v.uv * _MainTex_ST.xy + _MainTex_ST.zw;

                    return o;
                }

                fixed4 frag(v2f i) : SV_Target{
                    fixed3 worldNormal = normalize(i.worldNormal); 
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                    // 对纹理进行采样
                    fixed4 texColor = tex2D(_MainTex,i.uv);

                    // 获得该物体的反射率
                    fixed3 albedo = texColor.rgb * _Color.rgb;

                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                    // 计算漫反射光照
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldLightDir,worldNormal));

                    return fixed4(ambient+diffuse,texColor.a * _AlphaScale);
                }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}