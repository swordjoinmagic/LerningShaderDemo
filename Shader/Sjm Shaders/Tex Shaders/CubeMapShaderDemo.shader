/*
    目标是编写一个 用于环境映射（反射）的立方体纹理shader
    支持CubeMap贴图、漫反射、高光反射、阴影投射的shader练习
*/
Shader "SJM/Cube Map Demo" {
    Properties {
        // 立方体纹理
        _CubeMap("Reflection Cube Map",Cube) = "_SkyBox" {}
        // 用于控制物体的整体颜色
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 物体高光反射颜色
        _Specular("Specular Color",Color) = (1, 1, 1, 1)
        // 光泽度
        _Gloss("Gloss",Range(8.0,256)) = 20
        // 用于控制反射的颜色
        _ReflectColor("Reflection Color",Color) = (1, 1, 1, 1)
        // 用于控制反射的程度
        _ReflectAmount("Reflect Amount",Range(0,1)) = 1
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
                // 正确赋值光照衰减值等阴影计算值的预编译指令
                #pragma multi_compile_fwdbase

                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"
                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                samplerCUBE _CubeMap;
                fixed4 _Color;
                fixed4 _Specular;
                float _Gloss;
                fixed4 _ReflectColor;
                fixed _ReflectAmount;

                struct a2v{
                    float4 vertex : POSITION;
                    // 法线,后续用于计算光照以及反射方向
                    float3 normal : NORMAL;
                    float2 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    // 世界坐标法线
                    float3 worldNormal : TEXCOORD0;
                    // 世界坐标下的顶点位置
                    float3 worldPos : TEXCOORD1;
                    // 模型纹理坐标
                    float2 uv : TEXCOORD2;

                    SHADOW_COORDS(3)
                };

                v2f vert(a2v v){
                    v2f o;
                    // 顶点变换
                    o.pos = UnityObjectToClipPos(v.vertex);
                    // 获得法线
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    // 获得模型纹理坐标
                    o.uv = v.texcoord;
                    // 获得顶点的世界坐标
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                    // 计算阴影值
                    TRANSFER_SHADOW(o);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    // 法线
                    fixed3 worldNormal = normalize(i.worldNormal);
                    // 光源方向
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                    // 视角方向
                    fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                    // 计算反射方向
                    float3 reflection = reflect(worldViewDir,worldNormal);

                    // 对立方体纹理进行采样
                    fixed3 albedo = texCUBE(_CubeMap,reflection).rgb * _ReflectColor.rgb;

                    // 环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                    // 计算漫反射光照
                    fixed3 diffuse = _LightColor0.rgb * max(0,dot(worldNormal,worldLightDir)) * _Color.rgb;

                    // 计算高光反射中的Blinn-Phong模型的half矢量
                    fixed3 halfDir = normalize(worldViewDir+worldLightDir);

                    // 计算高光反射
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                    // 计算阴影
                    UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                    // 混合最终颜色
                    fixed3 color = ambient + lerp((diffuse+specular),albedo,_ReflectAmount) * atten;

                    return fixed4(color,1.0);

                }

            ENDCG
        }


        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            CGPROGRAM
                // 正确赋值光照衰减值等阴影计算值的预编译指令
                #pragma multi_compile_fwdadd

                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"
                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                samplerCUBE _CubeMap;
                fixed4 _Color;
                fixed4 _Specular;
                float _Gloss;
                fixed4 _ReflectColor;
                fixed _ReflectAmount;

                struct a2v{
                    float4 vertex : POSITION;
                    // 法线,后续用于计算光照以及反射方向
                    float3 normal : NORMAL;
                    float2 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    // 世界坐标法线
                    float3 worldNormal : TEXCOORD0;
                    // 世界坐标下的顶点位置
                    float3 worldPos : TEXCOORD1;
                    // 模型纹理坐标
                    float2 uv : TEXCOORD2;

                    SHADOW_COORDS(3)

                    float3 worldViewDir : TEXCOORD4;
                    float3 worldReflection : TEXCOORD5;
                };

                v2f vert(a2v v){
                    v2f o;
                    // 顶点变换
                    o.pos = UnityObjectToClipPos(v.vertex);
                    // 获得法线
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    // 获得模型纹理坐标
                    o.uv = v.texcoord;
                    // 获得顶点的世界坐标
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                    o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                    o.worldReflection = reflect(-o.worldViewDir,o.worldNormal);

                    // 计算阴影值
                    TRANSFER_SHADOW(o);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    // 法线
                    fixed3 worldNormal = normalize(i.worldNormal);
                    // 光源方向
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                    // 视角方向
                    // fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                    fixed3 worldViewDir = normalize(i.worldViewDir);
                    // 计算反射方向
                    // float3 reflection = reflect(worldViewDir,worldNormal);

                    // 对立方体纹理进行采样
                    fixed3 albedo = texCUBE(_CubeMap,i.worldReflection).rgb * _ReflectColor.rgb;

                    // 环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                    // 计算漫反射光照
                    fixed3 diffuse = _LightColor0.rgb * max(0,dot(worldNormal,worldLightDir)) * _Color.rgb;

                    // 计算高光反射中的Blinn-Phong模型的half矢量
                    fixed3 halfDir = normalize(worldViewDir+worldLightDir);

                    // 计算高光反射
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                    // 计算阴影
                    UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                    // 混合最终颜色
                    fixed3 color = ambient + lerp((diffuse+specular),albedo,_ReflectAmount) * atten;

                    return fixed4(color,1.0);

                }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}