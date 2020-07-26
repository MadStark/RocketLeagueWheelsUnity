Shader "Custom/Wheels/Infinium"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _ParallaxOffsetStep ("Parallax Offset Step", Vector) = (0.05, 0.05, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        ZWrite On

        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float3 viewDirTS : TEXCOORD1;
            };

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap); float4 _BaseMap_ST;
            half4 _BaseColor;
            float2 _ParallaxOffsetStep;

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                output.color = _BaseColor;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

                float tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                float3 tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
                float3x3 tangentToWorld = CreateTangentToWorld(normalWS, tangentWS, tangentSign);
                float3 viewDir = vertexInput.positionWS.xyz - _WorldSpaceCameraPos;
                output.viewDirTS = TransformWorldToTangent(viewDir, tangentToWorld);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 color = (half4)0;

                int count = 10;
                float offset = _ParallaxOffsetStep.x;
                float3 viewDirTS = normalize(input.viewDirTS);

                UNITY_UNROLL
                for (int i = count; i >= 0; i--)
                {
                    // Offset by view direction and sample the texture
                    float2 texoffset = input.viewDirTS.xy * offset;
                    float fadeaway = (float)i / count;
                    half4 layer = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv + texoffset) * fadeaway;

                    // Blend layer with the previous layers
                    color = max(layer, color);

                    // Increase offset
                    offset += _ParallaxOffsetStep.y;
                }

                color *= input.color;
                return color;
            }
            ENDHLSL
        }
    }
}
