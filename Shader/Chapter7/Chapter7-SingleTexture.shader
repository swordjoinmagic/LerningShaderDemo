// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Single Texture" {
    Properties {
        // 用于控制物体整体色调
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 纹理
        _MainTex("Main Tex",2D) = "while" {}
        // 材质的高光反射颜色
        _Specular("Specular",Color) = (1, 1, 1, 1)
        // 光泽度
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader {
        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed4 _Specular;
                float _Gloss;

                // 定义顶点着色器的输入
                struct a2v{
                    // 模型空间下的顶点坐标
                    float4 vertex : POSITION;
                    // 顶点法线
                    float3 normal : NORMAL;
                    // 纹理
                    float4 texcoord : TEXCOORD0;
                };

                // 定义顶点着色器的输出
                struct v2f{
                    // 裁剪空间下的顶点坐标
                    float4 pos : SV_POSITION;
                    // 世界坐标的顶点法线
                    float3 worldNormal : TEXCOORD0;
                    // 在世界坐标下的顶点坐标
                    float3 worldPos : TEXCOORD1;
                    // uv坐标
                    float2 uv : TEXCOORD2;
                };

                v2f vert(a2v v){
                    v2f o;

                    // 变换顶点
                    o.pos = UnityObjectToClipPos(v.vertex);

                    // 获得世界坐标下的法线
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);

                    // 获得当前顶点在世界坐标下的顶点坐标
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                    // 获取uv坐标,此处将原本的 纹理坐标 * 缩放 + 偏移
                    o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                    
                    return o;
                }

                fixed4 frag(v2f v) : SV_TARGET{
                    // 获得世界坐标下的单位顶点法线
                    fixed3 worldNormal = normalize(v.worldNormal);
                    // 获得光源方向的单位矢量
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(v.worldPos));

                    // 使用tex2D函数对纹理进行采样,alebdo表示材质的反射率
                    fixed3 albedo = tex2D(_MainTex,v.uv).rgb * _Color.rgb;

                    // 获得观察方向
                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(v.worldPos));
                    // 获得blinn-phong模型的half矢量
                    fixed3 halfDir = normalize(worldLightDir+viewDir);
                    // 获得高光反射
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);
                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                    // 获得漫反射光照
                    fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal,worldLightDir));

                    return fixed4(ambient+diffuse+specular,1.0);

                }

            ENDCG
        }
    }
    FallBack "Diffuse"
}