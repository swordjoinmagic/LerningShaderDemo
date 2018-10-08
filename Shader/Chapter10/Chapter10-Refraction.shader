Shader "Unity Shaders Book/Chapter 10/Refraction" {
    Properties {
        // 用于控制整体的颜色
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 物体折射颜色
        _RefractColor("Refraction Color",Color) = (1, 1, 1, 1)
        // 物体折射率
        _RefractAmount("Refraction Amount",Range(0,1)) = 1

        // 介质之间的透射比
        _RefractRadio("Refract Ratio",Range(0.1,1)) = 0.5

        // 立方体纹理
        _CubeMap("CubeMap",Cube) = "_Skybox" {}
    }
    SubShader {
        Tags{ "RenderType" = "Opaque" }
        Pass {
            Tags{ "LightMode" = "ForwardBase" }

            CGPROGRAM
                #pragma multi_compile_fwbase

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                fixed4 _Color;
                fixed4 _RefractColor;
                fixed _RefractAmount;
                fixed _RefractRadio;
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
                    float3 worldRefr : TEXCOORD3;
                    SHADOW_COORDS(4)
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                    o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                    o.worldRefr = refract(-normalize(o.worldViewDir),normalize(o.worldNormal),_RefractRadio);

                    TRANSFER_SHADOW(o);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed3 worldNormal = normalize(i.worldNormal);
                    fixed3 worldViewDir = normalize(i.worldViewDir);
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                    fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldNormal,worldLightDir));

                    // 对立方体纹理进行采样
                    fixed3 refraction = texCUBE(_CubeMap,i.worldRefr).rgb * _RefractColor.rgb;

                    // 计算阴影
                    UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                    fixed3 color = ambient + lerp(diffuse,refraction,_RefractAmount) * atten;

                    return fixed4(color,1.0);
                }
                
            ENDCG
        }
    }
    FallBack "Diffuse"
    
}