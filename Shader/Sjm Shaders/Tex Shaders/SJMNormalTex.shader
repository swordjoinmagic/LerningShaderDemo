// 支持高光反射、漫反射、阴影投射、单张2D纹理、法线映射、多光源照射的shader
Shader "SJM/Normal Tex" {
    Properties {
        // 用于控制整体颜色
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 主纹理
        _MainTex("Main Tex",2D) = "white" {}
        // 法线纹理
        _BumpTex("Bump",2D) = "bump" {}
        // 高光反射材质颜色
        _Specular("Specular",Color) = (1, 1, 1, 1)
        // 光泽度
        _Gloss("Gloss",Range(3.0,256)) = 20
        // 用于控制法线映射的凹凸程度
        _BumpScale("Bump Scale",Float) = 1.0
    }
    SubShader {
        // 设置该subShader渲染类型
        Tags{ "RenderType" = "Opaque" }

        // 前向渲染的BasePass
        Pass {

            Tags{ "LightMode" = "ForwardBase" }

            CGPROGRAM
                // BasePass的预编译指令
                #pragma multi_compile_fwdbase

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _BumpTex;
                float4 _BumpTex_ST;
                fixed4 _Specular;
                float _Gloss;
                float _BumpScale;
                fixed4 _Color;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    // 该顶点的切线
                    float4 tangent : TANGENT;
                    float2 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;

                    // 切线-世界 变换矩阵
                    float4 TtoW0 : TEXCOORD0;
                    float4 TtoW1 : TEXCOORD1;
                    float4 TtoW2 : TEXCOORD2;

                    // 纹理坐标,xy分量存储_MainTex的纹理坐标,zw分量存储_BumpTex的纹理坐标
                    float4 uv : TEXCOORD3;

                    // 阴影纹理坐标
                    SHADOW_COORDS(4)
                };

                v2f vert(a2v v){
                    v2f o;
                    // 变换顶点坐标到裁剪空间
                    o.pos = UnityObjectToClipPos(v.vertex);

                    // 获得顶点的世界坐标
                    float3 worldPos = mul(unity_ObjectToWorld,v.vertex);

                    // 获得顶点法线的世界坐标
                    fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal)); 

                    // 获得顶点切线的世界坐标
                    fixed4 worldTangent = normalize(mul(unity_ObjectToWorld,v.tangent));

                    // 获得顶点副切线世界坐标,其方向性由顶点的w分量决定
                    fixed3 worldBinormal = normalize( cross(worldNormal,worldTangent) * v.tangent.w ); 

                    // 构造 切线-世界 变换矩阵
                    // 其中法线是切线空间的z轴,切线是切线空间的x轴,副切线是切线空间y轴
                    // 现在有了他们在世界坐标的表示形式,只要将他们按xyz的形式按列排列就能获得 切线-世界 变换矩阵
                    o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                    o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                    o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                    o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                    o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpTex);

                    // 计算阴影纹理映射坐标
                    TRANSFER_SHADOW(o);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    // 获得顶点的世界坐标
                    float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                    // 获得光源方向
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                    // 获得顶点视角方向(用来算高光反射Blinn-Phong的)
                    fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                    // 获得在法线纹理中存储的(切线空间下的)法线
                    fixed3 bump = UnpackNormal(tex2D(_BumpTex,i.uv.zw));
                    // BumpScale控制凹凸程度
                    bump.xy *= _BumpScale;
                    // 根据xy获得z分量
                    bump.z = sqrt(1.0 - saturate( dot( bump.xy,bump.xy ) ));

                    // 将切线空间下的法线转变为世界坐标下的法线
                    bump = normalize(half3( dot(i.TtoW0.xyz,bump) , dot(i.TtoW1.xyz,bump) , dot(i.TtoW2.xyz,bump) ));

                    // 对主纹理进行采样
                    fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb * _Color.rgb;

                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
        
                    // 计算漫反射光照
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,worldLightDir));

                    // 计算高光反射Blinn-Phong模型中的Half矢量
                    fixed3 halfDir = normalize(worldViewDir+bump);

                    // 计算高光反射
                    fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(max(0,dot(halfDir,bump)),_Gloss);

                    // 计算阴影值
                    UNITY_LIGHT_ATTENUATION(atten,i,worldPos);

                    // 混合颜色
                    fixed3 color = ambient + (diffuse+specular) * atten;

                    return fixed4(color,1.0);
                }

            ENDCG
        }

        // 前向渲染的AddPass
        Pass{

            Tags{ "LightMode" = "ForwardAdd" }
            Blend One One

            CGPROGRAM
                // BasePass的预编译指令
                #pragma multi_compile_fwdadd

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _BumpTex;
                float4 _BumpTex_ST;
                fixed4 _Specular;
                float _Gloss;
                float _BumpScale;
                fixed4 _Color;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    // 该顶点的切线
                    float4 tangent : TANGENT;
                    float2 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;

                    // 切线-世界 变换矩阵
                    float4 TtoW0 : TEXCOORD0;
                    float4 TtoW1 : TEXCOORD1;
                    float4 TtoW2 : TEXCOORD2;

                    // 纹理坐标,xy分量存储_MainTex的纹理坐标,zw分量存储_BumpTex的纹理坐标
                    float4 uv : TEXCOORD3;

                    // 阴影纹理坐标
                    SHADOW_COORDS(4)
                };

                v2f vert(a2v v){
                    v2f o;
                    // 变换顶点坐标到裁剪空间
                    o.pos = UnityObjectToClipPos(v.vertex);

                    // 获得顶点的世界坐标
                    float3 worldPos = mul(unity_ObjectToWorld,v.vertex);

                    // 获得顶点法线的世界坐标
                    fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal)); 

                    // 获得顶点切线的世界坐标
                    fixed4 worldTangent = normalize(mul(unity_ObjectToWorld,v.tangent));

                    // 获得顶点副切线世界坐标,其方向性由顶点的w分量决定
                    fixed3 worldBinormal = normalize( cross(worldNormal,worldTangent) * v.tangent.w ); 

                    // 构造 切线-世界 变换矩阵
                    // 其中法线是切线空间的z轴,切线是切线空间的x轴,副切线是切线空间y轴
                    // 现在有了他们在世界坐标的表示形式,只要将他们按xyz的形式按列排列就能获得 切线-世界 变换矩阵
                    o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                    o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                    o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                    o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                    o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpTex);

                    // 计算阴影纹理映射坐标
                    TRANSFER_SHADOW(o);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    // 获得顶点的世界坐标
                    float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                    // 获得光源方向
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                    // 获得顶点视角方向(用来算高光反射Blinn-Phong的)
                    fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                    // 获得在法线纹理中存储的(切线空间下的)法线
                    fixed3 bump = UnpackNormal(tex2D(_BumpTex,i.uv.zw));
                    // BumpScale控制凹凸程度
                    bump.xy *= _BumpScale;
                    // 根据xy获得z分量
                    bump.z = sqrt(1.0 - saturate( dot( bump.xy,bump.xy ) ));

                    // 将切线空间下的法线转变为世界坐标下的法线
                    bump = normalize(half3( dot(i.TtoW0.xyz,bump) , dot(i.TtoW1.xyz,bump) , dot(i.TtoW2.xyz,bump) ));

                    // 对主纹理进行采样
                    fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb * _Color.rgb;

                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
        
                    // 计算漫反射光照
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,worldLightDir));

                    // 计算高光反射Blinn-Phong模型中的Half矢量
                    fixed3 halfDir = normalize(worldViewDir+bump);

                    // 计算高光反射
                    fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(max(0,dot(halfDir,bump)),_Gloss);

                    // 计算阴影值
                    UNITY_LIGHT_ATTENUATION(atten,i,worldPos);

                    // 混合颜色
                    fixed3 color = ambient + (diffuse+specular) * atten;

                    return fixed4(color,1.0);
                }

            ENDCG            
        }
    }
    FallBack "Diffuse"
    
}