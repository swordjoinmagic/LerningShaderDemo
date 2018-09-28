// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// 在世界坐标空间下计算光照
Shader "Unity Shaders Book/Chapter 7/NormalMapWorldSpace" {
    Properties {
        // 用于控制物体的整体颜色
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 输入纹理
        _MainTex("Main Tex",2D) = "white" {}
        // 法线纹理，其中bump是unity内置法线纹理
        _BumpMap("Normal Map",2D) = "bump" {}
        // 用于控制凹凸程度，为0时，
        // 表示该法线纹理不会对光照产生任何影响
        _BumpScale("Bump Scale",Float) = 1.0
        // 材质高光反射颜色
        _Specular("Specular",Color) = (1, 1, 1, 1)
        // 光泽度
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader {
        Pass {
            // 设置标签，设置为前向渲染模式
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

                // 定义顶点和片元着色器函数
                #pragma vertex vert
                #pragma fragment frag

                // 导入Unity内置包
                #include "Lighting.cginc"
                #include "UnityCG.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;     // 表示纹理的平铺和偏移系数属性
                sampler2D _BumpMap;
                float4 _BumpMap_ST;     // 表示法线纹理的平铺和偏移系数的属性
                float _BumpScale;
                fixed4 _Specular;
                float _Gloss;

                // 定义顶点着色器的输入
                struct a2v{
                  float4 vertex : POSITION;  
                  float3 normal : NORMAL;
                  float4 tangent : TANGENT;
                  float4 texcoord : TEXCOORD0;
                };
                // 定义顶点着色器的输出
                struct v2f{
                    float4 pos : SV_POSITION;
                    float4 uv : TEXCOORD0;
                    
                    // 对于矩阵变量,需要将其按行拆分成多个变量再进行存储
                    float4 TtoW0 : TEXCOORD1;
                    float4 TtoW1 : TEXCOORD2;
                    float4 TtoW2 : TEXCOORD3;
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);

                    o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                    o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                    // 将顶点变换到世界坐标空间下
                    float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                    // 将法线变换到世界坐标空间下
                    fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                    // 将切线变换到世界坐标空间下
                    fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                    // 计算副切线
                    fixed3 worldBinormal = cross(worldNormal,worldTangent)*v.tangent.w;

                    // 获得 切线-世界坐标 变换矩阵
                    o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                    o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                    o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    // 获得世界坐标下的顶点坐标
                    float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);                        
                    // 计算世界坐标下的法线和光源方向
                    fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                    // 计算在切线空间下的切线坐标
                    fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                    bump.xy *= _BumpScale;
                    bump.z = sqrt(1.0 - saturate(dot(bump.xy,bump.xy)));

                    // 将切线变换到世界坐标下
                    bump = normalize(
                        half3( dot(i.TtoW0.xyz,bump) , dot(i.TtoW1.xyz,bump) , dot(i.TtoW2.xyz,bump))
                    );

                    // 获得材质反射率（相当于根据纹理给材质上色的那个颜色？）
                    fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

                    //======================================================
                    // 下面计算标准光照模型

                    // 获得环境光条件
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                    // 计算漫反射光照
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,lightDir));

                    // 计算bline-phong模型的half矢量
                    fixed3 haltDir = normalize(lightDir+viewDir);

                    // 计算高光反射光照
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(bump,haltDir)),_Gloss);

                    return fixed4(ambient+diffuse+specular,1.0);
                }
 
            ENDCG
        }
    }
    FallBack "Diffuse"
    
}