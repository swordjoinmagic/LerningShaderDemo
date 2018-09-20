// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chpater 6/DiffuseVertexLevel" {
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
					fixed3 color : COLOR;
				};

				// 顶点着色器
				v2f vert(a2v v){
					v2f o;
					// 将顶点从模型空间转换到裁剪空间
					o.pos = UnityObjectToClipPos(v.vertex);
					
					// 获得环境光条件
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

					// 变换法线从模型空间到世界坐标,
					// 这里的矩阵乘法之所以反过来,
					// 是因为要乘的是unity_WorldToObject的逆转置矩阵
					// 调换一下矩阵乘法的位置就可以达到这个目的了!
					fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
					// 获得在世界坐标下的光源方向
					fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

					// 计算漫反射,此处需要注意的是,
					// 在计算法线和光源方向之间的点积时,
					// 需要选择它们所在的坐标系,
					// 只有两者处于同一坐标空间下,它们的点积才有意义
					fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));

					o.color = ambient + diffuse;

					return o;
				}

				// 片元着色器
				fixed4 frag(v2f i) : SV_TARGET{
					return fixed4(i.color,1.0);
				}

			ENDCG
		}
	}
}