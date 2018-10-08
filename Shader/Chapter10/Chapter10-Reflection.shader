Shader "Unity Shaders Book/Chapter 10/Reflection" {
    Properties {
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 用于控制反射颜色
        _ReflectColor("Reflection Color",Color) = (1, 1, 1,1)
        // 用于控制这个材质的反射程度
        _ReflectAmount("Reflect Amount",Range(0,1)) = 1
        // 用于模拟反射的环境映射纹理
        _CubeMap("Reflection CubeMap",Cube) = "_Skybox" {}
    }
    SubShader {
        // 渲染不透明物体
        Tags { "RenderType" = "Opaque" }
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

                #pragma multi_compile_fwdbase

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                fixed4 _Color;
                fixed4 _ReflectColor;
                fixed _ReflectAmount;
                samplerCUBE _CubeMap;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };
                struct v2f{
                    float4 pos : SV_POSITION;
                    float3 worldNormal : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float3 worldViewDir : TEXCOORD2;
                    float3 worldRefl : TEXCOORD3;
                    SHADOW_COORDS(4)
                };

                v2f vert(a2v v){
                    v2f o;

                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                    o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

                    // 计算世界坐标下的反射方向
                    o.worldRefl = reflect(-o.worldViewDir,o.worldNormal);
                    // o.worldRefl = reflect(-_WorldSpaceLightPos0.xyz,o.worldNormal);

                    // 计算阴影映射纹理
                    TRANSFER_SHADOW(o);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed3 worldNormal = normalize(i.worldNormal);
                    fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);
                    fixed3 worldViewDir = normalize(i.worldViewDir);

                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                    fixed3 diffuse = _LightColor0.rgb  * _Color.rgb * max(0,dot(worldNormal,worldLightDir));

                    // 使用反射方向来对CubeMap纹理进行采样
                    fixed3 reflection = texCUBE(_CubeMap,i.worldRefl).rgb * _ReflectColor.rgb;

                    // 基于阴影映射纹理计算衰退值
                    UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                    // 计算颜色
                    fixed3 color = ambient + lerp(diffuse,reflection,_ReflectAmount)*atten;

                    return fixed4(color,1.0);
                }

            ENDCG

        }
    }
    FallBack "Diffuse"
    
}