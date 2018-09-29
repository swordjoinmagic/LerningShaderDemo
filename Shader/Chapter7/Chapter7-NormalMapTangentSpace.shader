// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/NormalMapTangentSpace" {
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
                    
                    // 这里使用float3的原因是，单位矢量的齐次坐标的第四个分量w为0，
                    // 简单来说就是对于单位矢量来说，有没有第四个分量都ok，所以这里
                    // 变成float3
                    float3 lightDir : TEXCOORD1; // 在切线空间下的光源方向
                    float3 viewDir : TEXCOORD2; // 在切线控件下的观察方向
                };

                v2f vert(a2v v){
                    v2f o;

                    // 必备事件之一：变换顶点位置到裁剪空间下
                    o.pos = UnityObjectToClipPos(v.vertex);

                    // 使用uv变量的前两格（xy）来保存该材质纹理的缩放以及偏移属性
                    o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                    // 使用uv变量的后两格（zw）来保存法线纹理的缩放以及偏移属性
                    o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                    //===================================
                    // 计算 模型-切线 变换矩阵

                    // 此处计算副切线
                    // 副切线由法线及顶点的切线方向叉积得到,切线的w分量决定了副切线的方向
                    float3 binormal = cross(normalize(v.normal),normalize(v.tangent.xyz)) * v.tangent.w;
                    // 获得该变换矩阵
                    float3x3 rotation = float3x3(
                        v.tangent.xyz,
                        binormal,
                        v.normal
                    );

                    // 将在模型空间下的光源方向转变为切线空间
                    o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                    o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    // 获得在切线空间下的光源方向以及观察方向
                    fixed3 tangentLightDir = normalize(i.lightDir);
                    fixed3 tangentViewDir = normalize(i.viewDir);

                    // 获得法线纹理中的纹素
                    fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);

                    // 在切线空间下的法线
                    fixed3 tangentNormal;

                    // 将纹素解包变成法线
                    tangentNormal = UnpackNormal(packedNormal);
                    tangentNormal.xy *= _BumpScale;
                    // 因为tangentNormal是单位矢量，所以已知xy，可以根据xy计算得到z分量，即x²+y²+z²=1
                    tangentNormal.z = sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                    // 获得材质反射率（相当于根据纹理给材质上色的那个颜色？）
                    fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb * _Color.rgb;

                    //======================================================
                    // 下面计算标准光照模型

                    // 获得环境光条件
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                    // 计算漫反射光照
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,tangentLightDir));

                    // 计算bline-phong模型的half矢量
                    fixed3 haltDir = normalize(tangentLightDir+tangentViewDir);

                    // 计算高光反射光照
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(tangentNormal,haltDir)),_Gloss);

                    return fixed4(ambient+diffuse+specular,1.0);
                }
            ENDCG
        }
    }
    FallBack "Diffuse"
    
}