// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// 逐顶点高光反射光照
Shader "Unity Shaders Book/Chapter 6/Specular Vertex-Level" {
    Properties {
        // 材质的漫反射颜色
        _Diffuse ("Diffuse",Color) = (1, 1, 1, 1)
        // 材质的光泽度
        _Gloss ("Gloss",Range(8.0,256)) = 20
        // 材质的高光反射颜色,用于控制材质对于高光反射的强度和颜色
        _Specular ("Specular",Color) = (1, 1, 1, 1)
    }
    SubShader {
        pass{
            
            // 定义该Pass在光照流水线中的角色
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            
            // 指定顶点/片元着色器
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
            };

            v2f vert(a2v v){
                v2f o;

                // 变换顶点坐标
                o.pos = UnityObjectToClipPos(v.vertex);

                // 获得环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 变换法线到世界坐标
                fixed3 wolrdNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));

                // 获得在世界坐标下的光源方向
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 计算漫反射光照
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(wolrdNormal,worldLightDir));

                // 获得在世界坐标下的反射方向,使用reflect函数计算反射方向,提供两个参数,一个是入射方向,此处为光源方向的反方向,二是法线方向
                fixed3 reflectDir = normalize(reflect(-worldLightDir,wolrdNormal));
                
                // 获得在世界坐标下的观察方向
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex).xyz);
 
                // 计算高光反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir,viewDir)),_Gloss);

                o.color = ambient + diffuse + specular;
                // o.color = ambient + specular;

                return o;
            } 

            fixed4 frag(v2f i) : SV_Target{
                return fixed4(i.color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}