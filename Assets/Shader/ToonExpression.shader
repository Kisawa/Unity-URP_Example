Shader "Unlit/ToonExpression"
{
    Properties
    {
		_Color("Base Color", Color) = (1, 1, 1, 1)
		_CoverColor("Cover Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
		[HideInInspector]_PerspectiveCorrectUsage("Perspective Correct Usage", Range(0, 1)) = 0
		[HideInInspector]_BoundCenterPosWS("Bound Center PositionWS", Vector) = (0, 0, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "UniversalMaterialType" = "Lit" }

		HLSLINCLUDE
		#include "CommonPass.hlsl"
		sampler2D _MainTex;
		CBUFFER_START(UnityPerMaterial)
		half4 _Color;
		half4 _CoverColor;
        float4 _MainTex_ST;
		half _PerspectiveCorrectUsage;
		float3 _BoundCenterPosWS;
		CBUFFER_END

		float4 PerspectiveCorrect(float4 positionCS)
		{
			float centerPosVS_z = TransformWorldToView(_BoundCenterPosWS).z;
			float2 newPosCS_xy = positionCS.xy;
			newPosCS_xy *= abs(positionCS.w);
			newPosCS_xy *= rcp(abs(centerPosVS_z));
			positionCS.xy = lerp(positionCS.xy, newPosCS_xy, _PerspectiveCorrectUsage);
			return positionCS;
		}
		ENDHLSL

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
			Cull Back ZTest LEqual ZWrite Off Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			
            struct Attributes
			{
				float3 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float3 uv : TEXCOORD0;
			};

            Varyings vert (Attributes input)
            {
                Varyings output;
				output.positionCS = PerspectiveCorrect(TransformObjectToHClip(input.positionOS));
				output.uv.xy = TRANSFORM_TEX(input.uv, _MainTex);
				output.uv.z = ComputeFogFactor(output.positionCS.z);
				return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                half4 col = tex2D(_MainTex, input.uv.xy) * _Color;
				col.xyz = MixFog(col.xyz, input.uv.z);
                return col;
            }
            ENDHLSL
        }

		Pass
        {
            Tags { "LightMode" = "StencilExpression" }
			Cull Back ZTest GEqual ZWrite Off Blend SrcAlpha OneMinusSrcAlpha
			Stencil
			{
				Ref 27
				Comp Equal
			}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
			{
				float3 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float3 uv : TEXCOORD0;
			};

            Varyings vert (Attributes input)
            {
                Varyings output;
				output.positionCS = PerspectiveCorrect(TransformObjectToHClip(input.positionOS));
				output.uv.xy = TRANSFORM_TEX(input.uv, _MainTex);
				output.uv.z = ComputeFogFactor(output.positionCS.z);
				return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                half4 col = tex2D(_MainTex, input.uv.xy) * _CoverColor;
				col.xyz = MixFog(col.xyz, input.uv.z);
                return col;
            }
            ENDHLSL
        }
    }
}
