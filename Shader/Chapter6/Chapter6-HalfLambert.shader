// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unity Shaders Book/Chpater 6/HalfLambert" {
	Properties {
		// 得到材质的漫反射颜色
		_Diffuse("Diffuse",Color) = (1, 1, 1, 1)
	}
	SubShader {
		pass{
			Tags {"LightMode" = "ForwardBase"}

			CGPROGRAM
				
				// 定义顶点/片元着色器函数
				#pragma vertex vert
				#pragma fragment frag

				// 导入Untiy内置函数包
				#include "Lighting.cginc"

				// 获得物体材质的漫反射颜色
				float4 _Diffuse;

				// 定义顶点着色器的输入结构体
				struct a2v{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
				};
				// 输出结构体
				struct v2f{
					float4 pos : SV_POSITION;
					float3 worldNormal : TEXCOORD0;
				};

				// 顶点着色器
				v2f vert(a2v v){
					v2f o;
					// 将顶点从模型空间转换到裁剪空间
					o.pos = UnityObjectToClipPos(v.vertex);
					
                    // 获得世界坐标下的法线
                    o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);

					return o;
				}

				// 片元着色器
				fixed4 frag(v2f i) : SV_TARGET{
                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                    // 获得世界坐标下的法线
                    fixed3 normal = normalize(i.worldNormal);
                    // 获得世界坐标下的光源方向
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                    // 计算漫反射,
                    // 光源颜色 * 材质漫反射颜色 * max(0,光源方向与表面发现的点积)
					fixed haltLambert = dot(normal,worldLightDir)*0.5 + 0.5;
                    fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * haltLambert;

                    fixed3 color = ambient + diffuse;
					return fixed4(color,1.0);
				}

			ENDCG
		}
	}
}