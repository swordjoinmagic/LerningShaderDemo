/*
    使用噪声纹理来创造物体的消融效果

    基本原理是：
        对噪声纹理进行采样，让采样的结果和某个控制消融程度阈值比较，
        如果小于阈值，就使用clip函数把他对应的像素裁剪掉，这些部分对应了图中被
        “烧毁”的区域。
        镂空区域边缘的烧焦效果是将两种颜色混合，再用pow函数处理，与原纹理颜色混合后的结果
*/
Shader "SJM/Burn Noise" {
    Properties {
        // 用于控制消融程度
        _BurnAmount("Burn Amount",Range(0.0,1.0)) = 0
        // 用于控制模拟烧焦效果时的线宽，值越大，蔓延范围越广
        _LineWidth("Burn Line Width",Range(0.0,0.2)) = 0.1
        // 漫反射纹理
        _MainTex("Main Tex",2D) = "white" {}
        // 法线纹理
        _BumpMap("Normal Map",2D) = "bump" {}
        // 火焰边缘的一种颜色值
        _BurnFirstColor("Burn First Color",Color) = (1, 0, 0, 1)
        // 火焰边缘的第二种颜色值
        _BurnSecondColor("Burn Second Color",Color) = (1, 0, 0, 1)
        // 噪声纹理
        _BurnMap("Burn Map",2D) = "white" {}
    }
    SubShader {
        
        Pass {
            Tags { "LightMode" = "ForwardBase" } 
            Cull Off
            CGPROGRAM

                // 用于计算阴影值的预编译指令
                #pragma multi_compile_fwdbase

                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCg.cginc"
                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                fixed _BurnAmount;
                fixed _LineWidth;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _BumpMap;
                float4 _BumpMap_ST;
                sampler2D _BurnMap;
                float4 _BurnMap_ST;
                fixed4 _BurnFirstColor;
                fixed4 _BurnSecondColor;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 texcoord : TEXCOORD0;
                    float4 tangent : TANGENT;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    // 用于对主纹理和法线纹理进行采样
                    float4 uv : TEXCOORD0;
                    // 用于对噪声纹理采样
                    float2 burnMapUV : TEXCOORD1;

                    // 用于 切线-世界 坐标变化的矩阵
                    float4 TtoW0 : TEXCOORD2;
                    float4 TtoW1 : TEXCOORD3;
                    float4 TtoW2 : TEXCOORD4;

                    // 阴影纹理
                    SHADOW_COORDS(5)
                };

                v2f vert(a2v v){
                    v2f o;
                    // 顶点变换
                    o.pos = UnityObjectToClipPos(v.vertex);

                    float4 worldPos = mul(unity_ObjectToWorld,v.vertex);
                    fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                    fixed3 worldTangent = mul(unity_ObjectToWorld,v.tangent);

                    // 依据法线和切线来计算副切线
                    fixed3 worldBinNormal = cross(worldNormal,worldTangent) * v.tangent.w;

                    // 计算 切线-世界 变换矩阵
                    o.TtoW0 = float4(worldTangent.x,worldBinNormal.x,worldNormal.x,worldPos.x);
                    o.TtoW1 = float4(worldTangent.y,worldBinNormal.y,worldNormal.y,worldPos.y);
                    o.TtoW2 = float4(worldTangent.z,worldBinNormal.z,worldNormal.z,worldPos.z);

                    // 计算各个纹理的偏移
                    o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                    o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);
                    o.burnMapUV = TRANSFORM_TEX(v.texcoord,_BurnMap);

                    // 计算阴影衰减值
                    TRANSFER_SHADOW(o);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{

                    // 对噪声纹理进行采样
                    fixed3 burn = tex2D(_BurnMap,i.burnMapUV).rgb;

                    // 根据阈值_BurnAmount来对物体进行裁剪
                    clip(burn.r - _BurnAmount);

                    // 获得世界坐标
                    float3 worldPos = float3(i.TtoW0.z,i.TtoW2.z,i.TtoW2.z);
                    // 获得光源方向
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                    // 获得切线空间下的法线
                    fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                    // 将法线从切线空间转换到世界坐标下
                    fixed3 worldNormal = normalize(half3(dot(i.TtoW0.xyz,tangentNormal),dot(i.TtoW1.xyz,tangentNormal),dot(i.TtoW2.xyz,tangentNormal)));

                    // 对主纹理进行采样
                    fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb;

                    fixed t = 1 - smoothstep(0.0,_LineWidth,burn.r - _BurnAmount);
                    fixed3 burnColor = lerp(_BurnFirstColor,_BurnSecondColor,t);

                    // 计算漫反射
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal,worldLightDir));

                    // 计算阴影衰退值
                    UNITY_LIGHT_ATTENUATION(atten,i,worldPos);

                    fixed3 finalColor = lerp(ambient+diffuse*atten,burnColor,t*step(0.0001,_BurnAmount));

                    return fixed4(finalColor,1);
                }

            ENDCG
        }        
    }
    FallBack "Diffuse"
    
}