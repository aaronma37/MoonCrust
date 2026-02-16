-- Auto-generated Vulkan FFI bindings for MoonCrust
local ffi = require('ffi')

ffi.cdef[[
    typedef unsigned char uint8_t;
    typedef unsigned short uint16_t;
    typedef unsigned int uint32_t;
    typedef unsigned long long uint64_t;
    typedef signed char int8_t;
    typedef short int16_t;
    typedef int int32_t;
    typedef long long int64_t;
    typedef size_t size_t;
    typedef size_t uintptr_t;
    typedef uint32_t VkSampleMask;
    typedef uint32_t VkBool32;
    typedef uint32_t VkFlags;
    typedef uint64_t VkFlags64;
    typedef uint64_t VkDeviceSize;
    typedef uint64_t VkDeviceAddress;
    typedef VkFlags VkFramebufferCreateFlags;
    typedef VkFlags VkQueryPoolCreateFlags;
    typedef VkFlags VkRenderPassCreateFlags;
    typedef VkFlags VkSamplerCreateFlags;
    typedef VkFlags VkPipelineLayoutCreateFlags;
    typedef VkFlags VkPipelineCacheCreateFlags;
    typedef VkFlags VkPipelineDepthStencilStateCreateFlags;
    typedef VkFlags VkPipelineDynamicStateCreateFlags;
    typedef VkFlags VkPipelineColorBlendStateCreateFlags;
    typedef VkFlags VkPipelineMultisampleStateCreateFlags;
    typedef VkFlags VkPipelineRasterizationStateCreateFlags;
    typedef VkFlags VkPipelineViewportStateCreateFlags;
    typedef VkFlags VkPipelineTessellationStateCreateFlags;
    typedef VkFlags VkPipelineInputAssemblyStateCreateFlags;
    typedef VkFlags VkPipelineVertexInputStateCreateFlags;
    typedef VkFlags VkPipelineShaderStageCreateFlags;
    typedef VkFlags VkDescriptorSetLayoutCreateFlags;
    typedef VkFlags VkBufferViewCreateFlags;
    typedef VkFlags VkInstanceCreateFlags;
    typedef VkFlags VkDeviceCreateFlags;
    typedef VkFlags VkDeviceQueueCreateFlags;
    typedef VkFlags VkQueueFlags;
    typedef VkFlags VkMemoryPropertyFlags;
    typedef VkFlags VkMemoryHeapFlags;
    typedef VkFlags VkAccessFlags;
    typedef VkFlags VkBufferUsageFlags;
    typedef VkFlags VkBufferCreateFlags;
    typedef VkFlags VkShaderStageFlags;
    typedef VkFlags VkImageUsageFlags;
    typedef VkFlags VkImageCreateFlags;
    typedef VkFlags VkImageViewCreateFlags;
    typedef VkFlags VkPipelineCreateFlags;
    typedef VkFlags VkColorComponentFlags;
    typedef VkFlags VkFenceCreateFlags;
    typedef VkFlags VkSemaphoreCreateFlags;
    typedef VkFlags VkFormatFeatureFlags;
    typedef VkFlags VkQueryControlFlags;
    typedef VkFlags VkQueryResultFlags;
    typedef VkFlags VkShaderModuleCreateFlags;
    typedef VkFlags VkEventCreateFlags;
    typedef VkFlags VkCommandPoolCreateFlags;
    typedef VkFlags VkCommandPoolResetFlags;
    typedef VkFlags VkCommandBufferResetFlags;
    typedef VkFlags VkCommandBufferUsageFlags;
    typedef VkFlags VkQueryPipelineStatisticFlags;
    typedef VkFlags VkMemoryMapFlags;
    typedef VkFlags VkMemoryUnmapFlags;
    typedef VkFlags VkImageAspectFlags;
    typedef VkFlags VkSparseMemoryBindFlags;
    typedef VkFlags VkSparseImageFormatFlags;
    typedef VkFlags VkSubpassDescriptionFlags;
    typedef VkFlags VkPipelineStageFlags;
    typedef VkFlags VkSampleCountFlags;
    typedef VkFlags VkAttachmentDescriptionFlags;
    typedef VkFlags VkStencilFaceFlags;
    typedef VkFlags VkCullModeFlags;
    typedef VkFlags VkDescriptorPoolCreateFlags;
    typedef VkFlags VkDescriptorPoolResetFlags;
    typedef VkFlags VkDependencyFlags;
    typedef VkFlags VkSubgroupFeatureFlags;
    typedef VkFlags VkIndirectCommandsLayoutUsageFlagsNV;
    typedef VkFlags VkIndirectStateFlagsNV;
    typedef VkFlags VkGeometryFlagsKHR;
    typedef VkFlags VkGeometryInstanceFlagsKHR;
    typedef VkFlags VkClusterAccelerationStructureGeometryFlagsNV;
    typedef VkFlags VkClusterAccelerationStructureClusterFlagsNV;
    typedef VkFlags VkClusterAccelerationStructureAddressResolutionFlagsNV;
    typedef VkFlags VkBuildAccelerationStructureFlagsKHR;
    typedef VkFlags VkPrivateDataSlotCreateFlags;
    typedef VkFlags VkAccelerationStructureCreateFlagsKHR;
    typedef VkFlags VkDescriptorUpdateTemplateCreateFlags;
    typedef VkFlags VkPipelineCreationFeedbackFlags;
    typedef VkFlags VkPerformanceCounterDescriptionFlagsKHR;
    typedef VkFlags VkAcquireProfilingLockFlagsKHR;
    typedef VkFlags VkSemaphoreWaitFlags;
    typedef VkFlags VkPipelineCompilerControlFlagsAMD;
    typedef VkFlags VkShaderCorePropertiesFlagsAMD;
    typedef VkFlags VkDeviceDiagnosticsConfigFlagsNV;
    typedef VkFlags VkRefreshObjectFlagsKHR;
    typedef VkFlags64 VkAccessFlags2;
    typedef VkFlags64 VkPipelineStageFlags2;
    typedef VkFlags VkAccelerationStructureMotionInfoFlagsNV;
    typedef VkFlags VkAccelerationStructureMotionInstanceFlagsNV;
    typedef VkFlags64 VkFormatFeatureFlags2;
    typedef VkFlags VkRenderingFlags;
    typedef VkFlags64 VkMemoryDecompressionMethodFlagsEXT;
    typedef VkFlags VkBuildMicromapFlagsEXT;
    typedef VkFlags VkMicromapCreateFlagsEXT;
    typedef VkFlags VkIndirectCommandsLayoutUsageFlagsEXT;
    typedef VkFlags VkIndirectCommandsInputModeFlagsEXT;
    typedef VkFlags VkDirectDriverLoadingFlagsLUNARG;
    typedef VkFlags64 VkPipelineCreateFlags2;
    typedef VkFlags64 VkBufferUsageFlags2;
    typedef VkFlags VkAddressCopyFlagsKHR;
    typedef VkFlags64 VkTensorCreateFlagsARM;
    typedef VkFlags64 VkTensorUsageFlagsARM;
    typedef VkFlags64 VkTensorViewCreateFlagsARM;
    typedef VkFlags64 VkDataGraphPipelineSessionCreateFlagsARM;
    typedef VkFlags64 VkDataGraphPipelineDispatchFlagsARM;
    typedef VkFlags VkVideoEncodeRgbModelConversionFlagsVALVE;
    typedef VkFlags VkVideoEncodeRgbRangeCompressionFlagsVALVE;
    typedef VkFlags VkVideoEncodeRgbChromaOffsetFlagsVALVE;
    typedef VkFlags VkSpirvResourceTypeFlagsEXT;
    typedef VkFlags VkCompositeAlphaFlagsKHR;
    typedef VkFlags VkDisplayPlaneAlphaFlagsKHR;
    typedef VkFlags VkSurfaceTransformFlagsKHR;
    typedef VkFlags VkSwapchainCreateFlagsKHR;
    typedef VkFlags VkDisplayModeCreateFlagsKHR;
    typedef VkFlags VkDisplaySurfaceCreateFlagsKHR;
    typedef VkFlags VkAndroidSurfaceCreateFlagsKHR;
    typedef VkFlags VkViSurfaceCreateFlagsNN;
    typedef VkFlags VkWaylandSurfaceCreateFlagsKHR;
    typedef VkFlags VkUbmSurfaceCreateFlagsSEC;
    typedef VkFlags VkWin32SurfaceCreateFlagsKHR;
    typedef VkFlags VkXlibSurfaceCreateFlagsKHR;
    typedef VkFlags VkXcbSurfaceCreateFlagsKHR;
    typedef VkFlags VkDirectFBSurfaceCreateFlagsEXT;
    typedef VkFlags VkIOSSurfaceCreateFlagsMVK;
    typedef VkFlags VkMacOSSurfaceCreateFlagsMVK;
    typedef VkFlags VkMetalSurfaceCreateFlagsEXT;
    typedef VkFlags VkImagePipeSurfaceCreateFlagsFUCHSIA;
    typedef VkFlags VkStreamDescriptorSurfaceCreateFlagsGGP;
    typedef VkFlags VkHeadlessSurfaceCreateFlagsEXT;
    typedef VkFlags VkScreenSurfaceCreateFlagsQNX;
    typedef VkFlags VkPeerMemoryFeatureFlags;
    typedef VkFlags VkMemoryAllocateFlags;
    typedef VkFlags VkDeviceGroupPresentModeFlagsKHR;
    typedef VkFlags VkDebugReportFlagsEXT;
    typedef VkFlags VkCommandPoolTrimFlags;
    typedef VkFlags VkExternalMemoryHandleTypeFlagsNV;
    typedef VkFlags VkClusterAccelerationStructureIndexFormatFlagsNV;
    typedef VkFlags VkExternalMemoryFeatureFlagsNV;
    typedef VkFlags VkExternalMemoryHandleTypeFlags;
    typedef VkFlags VkExternalMemoryFeatureFlags;
    typedef VkFlags VkExternalSemaphoreHandleTypeFlags;
    typedef VkFlags VkExternalSemaphoreFeatureFlags;
    typedef VkFlags VkSemaphoreImportFlags;
    typedef VkFlags VkExternalFenceHandleTypeFlags;
    typedef VkFlags VkExternalFenceFeatureFlags;
    typedef VkFlags VkFenceImportFlags;
    typedef VkFlags VkSurfaceCounterFlagsEXT;
    typedef VkFlags VkPipelineViewportSwizzleStateCreateFlagsNV;
    typedef VkFlags VkPipelineDiscardRectangleStateCreateFlagsEXT;
    typedef VkFlags VkPipelineCoverageToColorStateCreateFlagsNV;
    typedef VkFlags VkPipelineCoverageModulationStateCreateFlagsNV;
    typedef VkFlags VkPipelineCoverageReductionStateCreateFlagsNV;
    typedef VkFlags VkValidationCacheCreateFlagsEXT;
    typedef VkFlags VkDebugUtilsMessageSeverityFlagsEXT;
    typedef VkFlags VkDebugUtilsMessageTypeFlagsEXT;
    typedef VkFlags VkDebugUtilsMessengerCreateFlagsEXT;
    typedef VkFlags VkDebugUtilsMessengerCallbackDataFlagsEXT;
    typedef VkFlags VkDeviceMemoryReportFlagsEXT;
    typedef VkFlags VkPipelineRasterizationConservativeStateCreateFlagsEXT;
    typedef VkFlags VkDescriptorBindingFlags;
    typedef VkFlags VkConditionalRenderingFlagsEXT;
    typedef VkFlags VkResolveModeFlags;
    typedef VkFlags VkPipelineRasterizationStateStreamCreateFlagsEXT;
    typedef VkFlags VkPipelineRasterizationDepthClipStateCreateFlagsEXT;
    typedef VkFlags VkSwapchainImageUsageFlagsANDROID;
    typedef VkFlags VkToolPurposeFlags;
    typedef VkFlags VkSubmitFlags;
    typedef VkFlags VkImageFormatConstraintsFlagsFUCHSIA;
    typedef VkFlags VkHostImageCopyFlags;
    typedef VkFlags VkPartitionedAccelerationStructureInstanceFlagsNV;
    typedef VkFlags VkImageConstraintsInfoFlagsFUCHSIA;
    typedef VkFlags VkGraphicsPipelineLibraryFlagsEXT;
    typedef VkFlags VkImageCompressionFlagsEXT;
    typedef VkFlags VkImageCompressionFixedRateFlagsEXT;
    typedef VkFlags VkExportMetalObjectTypeFlagsEXT;
    typedef VkFlags VkRenderingAttachmentFlagsKHR;
    typedef VkFlags VkResolveImageFlagsKHR;
    typedef VkFlags VkDeviceAddressBindingFlagsEXT;
    typedef VkFlags VkOpticalFlowGridSizeFlagsNV;
    typedef VkFlags VkOpticalFlowUsageFlagsNV;
    typedef VkFlags VkOpticalFlowSessionCreateFlagsNV;
    typedef VkFlags VkOpticalFlowExecuteFlagsNV;
    typedef VkFlags VkFrameBoundaryFlagsEXT;
    typedef VkFlags VkPresentScalingFlagsKHR;
    typedef VkFlags VkPresentGravityFlagsKHR;
    typedef VkFlags VkShaderCreateFlagsEXT;
    typedef VkFlags VkTileShadingRenderPassFlagsQCOM;
    typedef VkFlags64 VkPhysicalDeviceSchedulingControlsFlagsARM;
    typedef VkFlags VkSurfaceCreateFlagsOHOS;
    typedef VkFlags VkPresentStageFlagsEXT;
    typedef VkFlags VkPastPresentationTimingFlagsEXT;
    typedef VkFlags VkPresentTimingInfoFlagsEXT;
    typedef VkFlags VkSwapchainImageUsageFlagsOHOS;
    typedef VkFlags VkPerformanceCounterDescriptionFlagsARM;
    typedef VkFlags VkVideoCodecOperationFlagsKHR;
    typedef VkFlags VkVideoCapabilityFlagsKHR;
    typedef VkFlags VkVideoSessionCreateFlagsKHR;
    typedef VkFlags VkVideoSessionParametersCreateFlagsKHR;
    typedef VkFlags VkVideoBeginCodingFlagsKHR;
    typedef VkFlags VkVideoEndCodingFlagsKHR;
    typedef VkFlags VkVideoCodingControlFlagsKHR;
    typedef VkFlags VkVideoDecodeUsageFlagsKHR;
    typedef VkFlags VkVideoDecodeCapabilityFlagsKHR;
    typedef VkFlags VkVideoDecodeFlagsKHR;
    typedef VkFlags VkVideoDecodeH264PictureLayoutFlagsKHR;
    typedef VkFlags VkVideoEncodeFlagsKHR;
    typedef VkFlags VkVideoEncodeUsageFlagsKHR;
    typedef VkFlags VkVideoEncodeContentFlagsKHR;
    typedef VkFlags VkVideoEncodeCapabilityFlagsKHR;
    typedef VkFlags VkVideoEncodeFeedbackFlagsKHR;
    typedef VkFlags VkVideoEncodeRateControlFlagsKHR;
    typedef VkFlags VkVideoEncodeRateControlModeFlagsKHR;
    typedef VkFlags VkVideoEncodeIntraRefreshModeFlagsKHR;
    typedef VkFlags VkVideoChromaSubsamplingFlagsKHR;
    typedef VkFlags VkVideoComponentBitDepthFlagsKHR;
    typedef VkFlags VkVideoEncodeH264CapabilityFlagsKHR;
    typedef VkFlags VkVideoEncodeH264StdFlagsKHR;
    typedef VkFlags VkVideoEncodeH264RateControlFlagsKHR;
    typedef VkFlags VkVideoEncodeH265CapabilityFlagsKHR;
    typedef VkFlags VkVideoEncodeH265StdFlagsKHR;
    typedef VkFlags VkVideoEncodeH265RateControlFlagsKHR;
    typedef VkFlags VkVideoEncodeH265CtbSizeFlagsKHR;
    typedef VkFlags VkVideoEncodeH265TransformBlockSizeFlagsKHR;
    typedef VkFlags VkVideoEncodeAV1CapabilityFlagsKHR;
    typedef VkFlags VkVideoEncodeAV1StdFlagsKHR;
    typedef VkFlags VkVideoEncodeAV1RateControlFlagsKHR;
    typedef VkFlags VkVideoEncodeAV1SuperblockSizeFlagsKHR;
    typedef VkFlags64 VkAccessFlags3KHR;
    typedef void VkRemoteAddressNV;
    typedef int VkMemoryUnmapFlagsKHR;
    typedef int VkGeometryFlagsNV;
    typedef int VkGeometryInstanceFlagsNV;
    typedef int VkBuildAccelerationStructureFlagsNV;
    typedef int VkPrivateDataSlotCreateFlagsEXT;
    typedef int VkDescriptorUpdateTemplateCreateFlagsKHR;
    typedef int VkPipelineCreationFeedbackFlagsEXT;
    typedef int VkSemaphoreWaitFlagsKHR;
    typedef int VkAccessFlags2KHR;
    typedef int VkPipelineStageFlags2KHR;
    typedef int VkFormatFeatureFlags2KHR;
    typedef int VkMemoryDecompressionMethodFlagsNV;
    typedef int VkRenderingFlagsKHR;
    typedef int VkPipelineCreateFlags2KHR;
    typedef int VkBufferUsageFlags2KHR;
    typedef int VkPeerMemoryFeatureFlagsKHR;
    typedef int VkMemoryAllocateFlagsKHR;
    typedef int VkCommandPoolTrimFlagsKHR;
    typedef int VkExternalMemoryHandleTypeFlagsKHR;
    typedef int VkExternalMemoryFeatureFlagsKHR;
    typedef int VkExternalSemaphoreHandleTypeFlagsKHR;
    typedef int VkExternalSemaphoreFeatureFlagsKHR;
    typedef int VkSemaphoreImportFlagsKHR;
    typedef int VkExternalFenceHandleTypeFlagsKHR;
    typedef int VkExternalFenceFeatureFlagsKHR;
    typedef int VkFenceImportFlagsKHR;
    typedef int VkDescriptorBindingFlagsEXT;
    typedef int VkResolveModeFlagsKHR;
    typedef int VkToolPurposeFlagsEXT;
    typedef int VkSubmitFlagsKHR;
    typedef int VkHostImageCopyFlagsEXT;
    typedef int VkPresentScalingFlagsEXT;
    typedef int VkPresentGravityFlagsEXT;
    typedef int VkAttachmentLoadOp;
    typedef int VkAttachmentStoreOp;
    typedef int VkBlendFactor;
    typedef int VkBlendOp;
    typedef int VkBorderColor;
    typedef int VkFramebufferCreateFlagBits;
    typedef int VkQueryPoolCreateFlagBits;
    typedef int VkRenderPassCreateFlagBits;
    typedef int VkSamplerCreateFlagBits;
    typedef int VkPipelineCacheHeaderVersion;
    typedef int VkPipelineCacheCreateFlagBits;
    typedef int VkPipelineShaderStageCreateFlagBits;
    typedef int VkDescriptorSetLayoutCreateFlagBits;
    typedef int VkInstanceCreateFlagBits;
    typedef int VkDeviceQueueCreateFlagBits;
    typedef int VkBufferCreateFlagBits;
    typedef int VkBufferUsageFlagBits;
    typedef int VkColorComponentFlagBits;
    typedef int VkComponentSwizzle;
    typedef int VkCommandPoolCreateFlagBits;
    typedef int VkCommandPoolResetFlagBits;
    typedef int VkCommandBufferResetFlagBits;
    typedef int VkCommandBufferLevel;
    typedef int VkCommandBufferUsageFlagBits;
    typedef int VkCompareOp;
    typedef int VkCullModeFlagBits;
    typedef int VkDescriptorType;
    typedef int VkDeviceCreateFlagBits;
    typedef int VkDynamicState;
    typedef int VkFenceCreateFlagBits;
    typedef int VkPolygonMode;
    typedef int VkFormat;
    typedef int VkFormatFeatureFlagBits;
    typedef int VkFrontFace;
    typedef int VkMemoryMapFlagBits;
    typedef int VkImageAspectFlagBits;
    typedef int VkImageCreateFlagBits;
    typedef int VkImageLayout;
    typedef int VkImageTiling;
    typedef int VkImageType;
    typedef int VkImageUsageFlagBits;
    typedef int VkImageViewCreateFlagBits;
    typedef int VkImageViewType;
    typedef int VkIndirectCommandsTokenTypeEXT;
    typedef int VkSharingMode;
    typedef int VkIndexType;
    typedef int VkLogicOp;
    typedef int VkMemoryHeapFlagBits;
    typedef int VkAccessFlagBits;
    typedef int VkMemoryPropertyFlagBits;
    typedef int VkPhysicalDeviceType;
    typedef int VkPipelineBindPoint;
    typedef int VkPipelineCreateFlagBits;
    typedef int VkPrimitiveTopology;
    typedef int VkQueryControlFlagBits;
    typedef int VkQueryPipelineStatisticFlagBits;
    typedef int VkQueryResultFlagBits;
    typedef int VkQueryType;
    typedef int VkQueueFlagBits;
    typedef int VkSubpassContents;
    typedef int VkResult;
    typedef int VkShaderStageFlagBits;
    typedef int VkSparseMemoryBindFlagBits;
    typedef int VkStencilFaceFlagBits;
    typedef int VkStencilOp;
    typedef int VkStructureType;
    typedef int VkSystemAllocationScope;
    typedef int VkInternalAllocationType;
    typedef int VkSamplerAddressMode;
    typedef int VkFilter;
    typedef int VkSamplerMipmapMode;
    typedef int VkVertexInputRate;
    typedef int VkPipelineStageFlagBits;
    typedef int VkSparseImageFormatFlagBits;
    typedef int VkClusterAccelerationStructureIndexFormatFlagBitsNV;
    typedef int VkClusterAccelerationStructureTypeNV;
    typedef int VkClusterAccelerationStructureOpTypeNV;
    typedef int VkClusterAccelerationStructureOpModeNV;
    typedef int VkSampleCountFlagBits;
    typedef int VkAttachmentDescriptionFlagBits;
    typedef int VkDescriptorPoolCreateFlagBits;
    typedef int VkDependencyFlagBits;
    typedef int VkObjectType;
    typedef int VkEventCreateFlagBits;
    typedef int VkPipelineLayoutCreateFlagBits;
    typedef int VkSemaphoreCreateFlagBits;
    typedef int VkRayTracingInvocationReorderModeEXT;
    typedef int VkRayTracingInvocationReorderModeNV;
    typedef int VkIndirectCommandsLayoutUsageFlagBitsNV;
    typedef int VkIndirectCommandsTokenTypeNV;
    typedef int VkIndirectStateFlagBitsNV;
    typedef int VkPrivateDataSlotCreateFlagBits;
    typedef int VkPrivateDataSlotCreateFlagBitsEXT;
    typedef int VkDescriptorUpdateTemplateType;
    typedef int VkDescriptorUpdateTemplateTypeKHR;
    typedef int VkViewportCoordinateSwizzleNV;
    typedef int VkDiscardRectangleModeEXT;
    typedef int VkSubpassDescriptionFlagBits;
    typedef int VkPointClippingBehavior;
    typedef int VkPointClippingBehaviorKHR;
    typedef int VkCoverageModulationModeNV;
    typedef int VkCoverageReductionModeNV;
    typedef int VkValidationCacheHeaderVersionEXT;
    typedef int VkShaderInfoTypeAMD;
    typedef int VkQueueGlobalPriority;
    typedef int VkQueueGlobalPriorityKHR;
    typedef int VkQueueGlobalPriorityEXT;
    typedef int VkTimeDomainKHR;
    typedef int VkTimeDomainEXT;
    typedef int VkConservativeRasterizationModeEXT;
    typedef int VkResolveModeFlagBits;
    typedef int VkResolveModeFlagBitsKHR;
    typedef int VkDescriptorBindingFlagBits;
    typedef int VkDescriptorBindingFlagBitsEXT;
    typedef int VkConditionalRenderingFlagBitsEXT;
    typedef int VkSemaphoreType;
    typedef int VkSemaphoreTypeKHR;
    typedef int VkGeometryFlagBitsKHR;
    typedef int VkGeometryFlagBitsNV;
    typedef int VkGeometryInstanceFlagBitsKHR;
    typedef int VkGeometryInstanceFlagBitsNV;
    typedef int VkClusterAccelerationStructureAddressResolutionFlagBitsNV;
    typedef int VkClusterAccelerationStructureGeometryFlagBitsNV;
    typedef int VkClusterAccelerationStructureClusterFlagBitsNV;
    typedef int VkBuildAccelerationStructureFlagBitsKHR;
    typedef int VkBuildAccelerationStructureFlagBitsNV;
    typedef int VkAccelerationStructureCreateFlagBitsKHR;
    typedef int VkBuildAccelerationStructureModeKHR;
    typedef int VkCopyAccelerationStructureModeKHR;
    typedef int VkCopyAccelerationStructureModeNV;
    typedef int VkAccelerationStructureTypeKHR;
    typedef int VkAccelerationStructureTypeNV;
    typedef int VkGeometryTypeKHR;
    typedef int VkGeometryTypeNV;
    typedef int VkRayTracingShaderGroupTypeKHR;
    typedef int VkRayTracingShaderGroupTypeNV;
    typedef int VkAccelerationStructureMemoryRequirementsTypeNV;
    typedef int VkAccelerationStructureBuildTypeKHR;
    typedef int VkAccelerationStructureCompatibilityKHR;
    typedef int VkRayTracingLssIndexingModeNV;
    typedef int VkRayTracingLssPrimitiveEndCapsModeNV;
    typedef int VkShaderGroupShaderKHR;
    typedef int VkMemoryOverallocationBehaviorAMD;
    typedef int VkDeviceDiagnosticsConfigFlagBitsNV;
    typedef int VkPipelineCreationFeedbackFlagBits;
    typedef int VkPipelineCreationFeedbackFlagBitsEXT;
    typedef int VkPerformanceCounterScopeKHR;
    typedef int VkPerformanceCounterUnitKHR;
    typedef int VkPerformanceCounterStorageKHR;
    typedef int VkPerformanceCounterDescriptionFlagBitsKHR;
    typedef int VkAcquireProfilingLockFlagBitsKHR;
    typedef int VkSemaphoreWaitFlagBits;
    typedef int VkSemaphoreWaitFlagBitsKHR;
    typedef int VkPerformanceConfigurationTypeINTEL;
    typedef int VkQueryPoolSamplingModeINTEL;
    typedef int VkPerformanceOverrideTypeINTEL;
    typedef int VkPerformanceParameterTypeINTEL;
    typedef int VkPerformanceValueTypeINTEL;
    typedef int VkLineRasterizationMode;
    typedef int VkLineRasterizationModeKHR;
    typedef int VkLineRasterizationModeEXT;
    typedef int VkShaderModuleCreateFlagBits;
    typedef int VkPipelineCompilerControlFlagBitsAMD;
    typedef int VkShaderCorePropertiesFlagBitsAMD;
    typedef int VkRefreshObjectFlagBitsKHR;
    typedef int VkFaultLevel;
    typedef int VkFaultType;
    typedef int VkFaultQueryBehavior;
    typedef int VkPipelineMatchControl;
    typedef int VkSciSyncClientTypeNV;
    typedef int VkSciSyncPrimitiveTypeNV;
    typedef int VkToolPurposeFlagBits;
    typedef int VkToolPurposeFlagBitsEXT;
    typedef int VkFragmentShadingRateNV;
    typedef int VkFragmentShadingRateTypeNV;
    typedef int VkSubpassMergeStatusEXT;
    typedef int VkAccessFlagBits2;
    typedef int VkAccessFlagBits2KHR;
    typedef int VkPipelineStageFlagBits2;
    typedef int VkPipelineStageFlagBits2KHR;
    typedef int VkProvokingVertexModeEXT;
    typedef int VkPipelineCacheValidationVersion;
    typedef int VkImageFormatConstraintsFlagBitsFUCHSIA;
    typedef int VkHostImageCopyFlagBits;
    typedef int VkHostImageCopyFlagBitsEXT;
    typedef int VkImageConstraintsInfoFlagBitsFUCHSIA;
    typedef int VkFormatFeatureFlagBits2;
    typedef int VkFormatFeatureFlagBits2KHR;
    typedef int VkRenderingFlagBits;
    typedef int VkRenderingFlagBitsKHR;
    typedef int VkPipelineDepthStencilStateCreateFlagBits;
    typedef int VkPipelineColorBlendStateCreateFlagBits;
    typedef int VkImageCompressionFlagBitsEXT;
    typedef int VkImageCompressionFixedRateFlagBitsEXT;
    typedef int VkExportMetalObjectTypeFlagBitsEXT;
    typedef int VkPipelineRobustnessBufferBehavior;
    typedef int VkPipelineRobustnessBufferBehaviorEXT;
    typedef int VkPipelineRobustnessImageBehavior;
    typedef int VkPipelineRobustnessImageBehaviorEXT;
    typedef int VkRenderingAttachmentFlagBitsKHR;
    typedef int VkResolveImageFlagBitsKHR;
    typedef int VkDeviceAddressBindingFlagBitsEXT;
    typedef int VkDeviceAddressBindingTypeEXT;
    typedef int VkMicromapTypeEXT;
    typedef int VkBuildMicromapModeEXT;
    typedef int VkCopyMicromapModeEXT;
    typedef int VkBuildMicromapFlagBitsEXT;
    typedef int VkMicromapCreateFlagBitsEXT;
    typedef int VkOpacityMicromapFormatEXT;
    typedef int VkOpacityMicromapSpecialIndexEXT;
    typedef int VkDeviceFaultVendorBinaryHeaderVersionEXT;
    typedef int VkIndirectCommandsLayoutUsageFlagBitsEXT;
    typedef int VkIndirectExecutionSetInfoTypeEXT;
    typedef int VkIndirectCommandsInputModeFlagBitsEXT;
    typedef int VkFrameBoundaryFlagBitsEXT;
    typedef int VkMemoryDecompressionMethodFlagBitsEXT;
    typedef int VkMemoryDecompressionMethodFlagBitsNV;
    typedef int VkDepthBiasRepresentationEXT;
    typedef int VkDirectDriverLoadingModeLUNARG;
    typedef int VkPipelineCreateFlagBits2;
    typedef int VkPipelineCreateFlagBits2KHR;
    typedef int VkBufferUsageFlagBits2;
    typedef int VkBufferUsageFlagBits2KHR;
    typedef int VkPartitionedAccelerationStructureOpTypeNV;
    typedef int VkPartitionedAccelerationStructureInstanceFlagBitsNV;
    typedef int VkAntiLagModeAMD;
    typedef int VkAntiLagStageAMD;
    typedef int VkDisplacementMicromapFormatNV;
    typedef int VkShaderCreateFlagBitsEXT;
    typedef int VkShaderCodeTypeEXT;
    typedef int VkScopeKHR;
    typedef int VkComponentTypeKHR;
    typedef int VkScopeNV;
    typedef int VkComponentTypeNV;
    typedef int VkCubicFilterWeightsQCOM;
    typedef int VkBlockMatchWindowCompareModeQCOM;
    typedef int VkLayeredDriverUnderlyingApiMSFT;
    typedef int VkPhysicalDeviceLayeredApiKHR;
    typedef int VkCompressedTriangleFormatAMDX;
    typedef int VkDepthClampModeEXT;
    typedef int VkTileShadingRenderPassFlagBitsQCOM;
    typedef int VkCooperativeVectorMatrixLayoutNV;
    typedef int VkAddressCopyFlagBitsKHR;
    typedef int VkTensorCreateFlagBitsARM;
    typedef int VkTensorUsageFlagBitsARM;
    typedef int VkTensorTilingARM;
    typedef int VkTensorViewCreateFlagBitsARM;
    typedef int VkDataGraphPipelineSessionCreateFlagBitsARM;
    typedef int VkDataGraphPipelinePropertyARM;
    typedef int VkDataGraphPipelineSessionBindPointARM;
    typedef int VkDataGraphPipelineSessionBindPointTypeARM;
    typedef int VkDataGraphPipelineDispatchFlagBitsARM;
    typedef int VkPhysicalDeviceDataGraphProcessingEngineTypeARM;
    typedef int VkPhysicalDeviceDataGraphOperationTypeARM;
    typedef int VkDataGraphModelCacheTypeQCOM;
    typedef int VkVideoEncodeRgbModelConversionFlagBitsVALVE;
    typedef int VkVideoEncodeRgbRangeCompressionFlagBitsVALVE;
    typedef int VkVideoEncodeRgbChromaOffsetFlagBitsVALVE;
    typedef int VkDescriptorMappingSourceEXT;
    typedef int VkSpirvResourceTypeFlagBitsEXT;
    typedef int VkColorSpaceKHR;
    typedef int VkCompositeAlphaFlagBitsKHR;
    typedef int VkDisplayPlaneAlphaFlagBitsKHR;
    typedef int VkPresentModeKHR;
    typedef int VkSurfaceTransformFlagBitsKHR;
    typedef int VkDisplaySurfaceStereoTypeNV;
    typedef int VkDebugReportFlagBitsEXT;
    typedef int VkDebugReportObjectTypeEXT;
    typedef int VkDeviceMemoryReportEventTypeEXT;
    typedef int VkRasterizationOrderAMD;
    typedef int VkExternalMemoryHandleTypeFlagBitsNV;
    typedef int VkExternalMemoryFeatureFlagBitsNV;
    typedef int VkValidationCheckEXT;
    typedef int VkValidationFeatureEnableEXT;
    typedef int VkValidationFeatureDisableEXT;
    typedef int VkExternalMemoryHandleTypeFlagBits;
    typedef int VkExternalMemoryHandleTypeFlagBitsKHR;
    typedef int VkExternalMemoryFeatureFlagBits;
    typedef int VkExternalMemoryFeatureFlagBitsKHR;
    typedef int VkExternalSemaphoreHandleTypeFlagBits;
    typedef int VkExternalSemaphoreHandleTypeFlagBitsKHR;
    typedef int VkExternalSemaphoreFeatureFlagBits;
    typedef int VkExternalSemaphoreFeatureFlagBitsKHR;
    typedef int VkSemaphoreImportFlagBits;
    typedef int VkSemaphoreImportFlagBitsKHR;
    typedef int VkExternalFenceHandleTypeFlagBits;
    typedef int VkExternalFenceHandleTypeFlagBitsKHR;
    typedef int VkExternalFenceFeatureFlagBits;
    typedef int VkExternalFenceFeatureFlagBitsKHR;
    typedef int VkFenceImportFlagBits;
    typedef int VkFenceImportFlagBitsKHR;
    typedef int VkSurfaceCounterFlagBitsEXT;
    typedef int VkDisplayPowerStateEXT;
    typedef int VkDeviceEventTypeEXT;
    typedef int VkDisplayEventTypeEXT;
    typedef int VkPeerMemoryFeatureFlagBits;
    typedef int VkPeerMemoryFeatureFlagBitsKHR;
    typedef int VkMemoryAllocateFlagBits;
    typedef int VkMemoryAllocateFlagBitsKHR;
    typedef int VkDeviceGroupPresentModeFlagBitsKHR;
    typedef int VkSwapchainCreateFlagBitsKHR;
    typedef int VkSubgroupFeatureFlagBits;
    typedef int VkTessellationDomainOrigin;
    typedef int VkTessellationDomainOriginKHR;
    typedef int VkSamplerYcbcrModelConversion;
    typedef int VkSamplerYcbcrModelConversionKHR;
    typedef int VkSamplerYcbcrRange;
    typedef int VkSamplerYcbcrRangeKHR;
    typedef int VkChromaLocation;
    typedef int VkChromaLocationKHR;
    typedef int VkSamplerReductionMode;
    typedef int VkSamplerReductionModeEXT;
    typedef int VkBlendOverlapEXT;
    typedef int VkDebugUtilsMessageSeverityFlagBitsEXT;
    typedef int VkDebugUtilsMessageTypeFlagBitsEXT;
    typedef int VkFullScreenExclusiveEXT;
    typedef int VkShaderFloatControlsIndependence;
    typedef int VkShaderFloatControlsIndependenceKHR;
    typedef int VkSwapchainImageUsageFlagBitsANDROID;
    typedef int VkFragmentShadingRateCombinerOpKHR;
    typedef int VkSubmitFlagBits;
    typedef int VkSubmitFlagBitsKHR;
    typedef int VkGraphicsPipelineLibraryFlagBitsEXT;
    typedef int VkOpticalFlowGridSizeFlagBitsNV;
    typedef int VkOpticalFlowUsageFlagBitsNV;
    typedef int VkOpticalFlowPerformanceLevelNV;
    typedef int VkOpticalFlowSessionBindingPointNV;
    typedef int VkOpticalFlowSessionCreateFlagBitsNV;
    typedef int VkOpticalFlowExecuteFlagBitsNV;
    typedef int VkDeviceFaultAddressTypeEXT;
    typedef int VkPresentScalingFlagBitsKHR;
    typedef int VkPresentScalingFlagBitsEXT;
    typedef int VkPresentGravityFlagBitsKHR;
    typedef int VkPresentGravityFlagBitsEXT;
    typedef int VkLayerSettingTypeEXT;
    typedef int VkLatencyMarkerNV;
    typedef int VkOutOfBandQueueTypeNV;
    typedef int VkPhysicalDeviceSchedulingControlsFlagBitsARM;
    typedef int VkMemoryUnmapFlagBits;
    typedef int VkMemoryUnmapFlagBitsKHR;
    typedef int VkWaylandSurfaceCreateFlagBitsKHR;
    typedef int VkPresentStageFlagBitsEXT;
    typedef int VkPastPresentationTimingFlagBitsEXT;
    typedef int VkPresentTimingInfoFlagBitsEXT;
    typedef int VkSwapchainImageUsageFlagBitsOHOS;
    typedef int VkPerformanceCounterDescriptionFlagBitsARM;
    typedef int VkVendorId;
    typedef int VkDriverId;
    typedef int VkDriverIdKHR;
    typedef int VkShadingRatePaletteEntryNV;
    typedef int VkCoarseSampleOrderTypeNV;
    typedef int VkPipelineExecutableStatisticFormatKHR;
    typedef int VkVideoCodecOperationFlagBitsKHR;
    typedef int VkVideoChromaSubsamplingFlagBitsKHR;
    typedef int VkVideoComponentBitDepthFlagBitsKHR;
    typedef int VkVideoCapabilityFlagBitsKHR;
    typedef int VkVideoSessionCreateFlagBitsKHR;
    typedef int VkVideoSessionParametersCreateFlagBitsKHR;
    typedef int VkVideoCodingControlFlagBitsKHR;
    typedef int VkQueryResultStatusKHR;
    typedef int VkVideoDecodeUsageFlagBitsKHR;
    typedef int VkVideoDecodeCapabilityFlagBitsKHR;
    typedef int VkVideoDecodeH264PictureLayoutFlagBitsKHR;
    typedef int VkVideoEncodeFlagBitsKHR;
    typedef int VkVideoEncodeUsageFlagBitsKHR;
    typedef int VkVideoEncodeContentFlagBitsKHR;
    typedef int VkVideoEncodeTuningModeKHR;
    typedef int VkVideoEncodeCapabilityFlagBitsKHR;
    typedef int VkVideoEncodeFeedbackFlagBitsKHR;
    typedef int VkVideoEncodeRateControlModeFlagBitsKHR;
    typedef int VkVideoEncodeIntraRefreshModeFlagBitsKHR;
    typedef int VkVideoEncodeH264CapabilityFlagBitsKHR;
    typedef int VkVideoEncodeH264StdFlagBitsKHR;
    typedef int VkVideoEncodeH264RateControlFlagBitsKHR;
    typedef int VkVideoEncodeH265CapabilityFlagBitsKHR;
    typedef int VkVideoEncodeH265StdFlagBitsKHR;
    typedef int VkVideoEncodeH265RateControlFlagBitsKHR;
    typedef int VkVideoEncodeH265CtbSizeFlagBitsKHR;
    typedef int VkVideoEncodeH265TransformBlockSizeFlagBitsKHR;
    typedef int VkVideoEncodeAV1CapabilityFlagBitsKHR;
    typedef int VkVideoEncodeAV1StdFlagBitsKHR;
    typedef int VkVideoEncodeAV1RateControlFlagBitsKHR;
    typedef int VkVideoEncodeAV1SuperblockSizeFlagBitsKHR;
    typedef int VkVideoEncodeAV1PredictionModeKHR;
    typedef int VkVideoEncodeAV1RateControlGroupKHR;
    typedef int VkAccessFlagBits3KHR;
    typedef int VkDefaultVertexAttributeValueKHR;
    typedef int VkAccelerationStructureMotionInstanceTypeNV;
    typedef uint32_t VkFlags;
    typedef uint64_t VkDeviceSize;
    typedef uint64_t VkDeviceAddress;
    typedef uint32_t VkSampleMask;
    typedef struct VkInstance_T* VkInstance;
    typedef struct VkPhysicalDevice_T* VkPhysicalDevice;
    typedef struct VkDevice_T* VkDevice;
    typedef struct VkQueue_T* VkQueue;
    typedef struct VkCommandBuffer_T* VkCommandBuffer;
    typedef struct VkDeviceMemory_T* VkDeviceMemory;
    typedef struct VkCommandPool_T* VkCommandPool;
    typedef struct VkBuffer_T* VkBuffer;
    typedef struct VkBufferView_T* VkBufferView;
    typedef struct VkImage_T* VkImage;
    typedef struct VkImageView_T* VkImageView;
    typedef struct VkShaderModule_T* VkShaderModule;
    typedef struct VkPipeline_T* VkPipeline;
    typedef struct VkPipelineLayout_T* VkPipelineLayout;
    typedef struct VkSampler_T* VkSampler;
    typedef struct VkDescriptorSet_T* VkDescriptorSet;
    typedef struct VkDescriptorSetLayout_T* VkDescriptorSetLayout;
    typedef struct VkDescriptorPool_T* VkDescriptorPool;
    typedef struct VkFence_T* VkFence;
    typedef struct VkSemaphore_T* VkSemaphore;
    typedef struct VkEvent_T* VkEvent;
    typedef struct VkQueryPool_T* VkQueryPool;
    typedef struct VkFramebuffer_T* VkFramebuffer;
    typedef struct VkRenderPass_T* VkRenderPass;
    typedef struct VkPipelineCache_T* VkPipelineCache;
    typedef struct VkPipelineBinaryKHR_T* VkPipelineBinaryKHR;
    typedef struct VkIndirectCommandsLayoutNV_T* VkIndirectCommandsLayoutNV;
    typedef struct VkIndirectCommandsLayoutEXT_T* VkIndirectCommandsLayoutEXT;
    typedef struct VkIndirectExecutionSetEXT_T* VkIndirectExecutionSetEXT;
    typedef struct VkDescriptorUpdateTemplate_T* VkDescriptorUpdateTemplate;
    typedef struct VkSamplerYcbcrConversion_T* VkSamplerYcbcrConversion;
    typedef struct VkValidationCacheEXT_T* VkValidationCacheEXT;
    typedef struct VkAccelerationStructureKHR_T* VkAccelerationStructureKHR;
    typedef struct VkAccelerationStructureNV_T* VkAccelerationStructureNV;
    typedef struct VkPerformanceConfigurationINTEL_T* VkPerformanceConfigurationINTEL;
    typedef struct VkBufferCollectionFUCHSIA_T* VkBufferCollectionFUCHSIA;
    typedef struct VkDeferredOperationKHR_T* VkDeferredOperationKHR;
    typedef struct VkPrivateDataSlot_T* VkPrivateDataSlot;
    typedef struct VkCuModuleNVX_T* VkCuModuleNVX;
    typedef struct VkCuFunctionNVX_T* VkCuFunctionNVX;
    typedef struct VkOpticalFlowSessionNV_T* VkOpticalFlowSessionNV;
    typedef struct VkMicromapEXT_T* VkMicromapEXT;
    typedef struct VkShaderEXT_T* VkShaderEXT;
    typedef struct VkTensorARM_T* VkTensorARM;
    typedef struct VkTensorViewARM_T* VkTensorViewARM;
    typedef struct VkDataGraphPipelineSessionARM_T* VkDataGraphPipelineSessionARM;
    typedef struct VkDisplayKHR_T* VkDisplayKHR;
    typedef struct VkDisplayModeKHR_T* VkDisplayModeKHR;
    typedef struct VkSurfaceKHR_T* VkSurfaceKHR;
    typedef struct VkSwapchainKHR_T* VkSwapchainKHR;
    typedef struct VkDebugReportCallbackEXT_T* VkDebugReportCallbackEXT;
    typedef struct VkDebugUtilsMessengerEXT_T* VkDebugUtilsMessengerEXT;
    typedef struct VkVideoSessionKHR_T* VkVideoSessionKHR;
    typedef struct VkVideoSessionParametersKHR_T* VkVideoSessionParametersKHR;
    typedef struct VkSemaphoreSciSyncPoolNV_T* VkSemaphoreSciSyncPoolNV;
    typedef struct VkBaseOutStructure VkBaseOutStructure;
    typedef struct VkBaseInStructure VkBaseInStructure;
    typedef struct VkOffset2D VkOffset2D;
    typedef struct VkOffset3D VkOffset3D;
    typedef struct VkExtent2D VkExtent2D;
    typedef struct VkExtent3D VkExtent3D;
    typedef struct VkViewport VkViewport;
    typedef struct VkRect2D VkRect2D;
    typedef struct VkClearRect VkClearRect;
    typedef struct VkComponentMapping VkComponentMapping;
    typedef struct VkPhysicalDeviceProperties VkPhysicalDeviceProperties;
    typedef struct VkExtensionProperties VkExtensionProperties;
    typedef struct VkLayerProperties VkLayerProperties;
    typedef struct VkApplicationInfo VkApplicationInfo;
    typedef struct VkAllocationCallbacks VkAllocationCallbacks;
    typedef struct VkDeviceQueueCreateInfo VkDeviceQueueCreateInfo;
    typedef struct VkDeviceCreateInfo VkDeviceCreateInfo;
    typedef struct VkInstanceCreateInfo VkInstanceCreateInfo;
    typedef struct VkQueueFamilyProperties VkQueueFamilyProperties;
    typedef struct VkPhysicalDeviceMemoryProperties VkPhysicalDeviceMemoryProperties;
    typedef struct VkMemoryAllocateInfo VkMemoryAllocateInfo;
    typedef struct VkMemoryRequirements VkMemoryRequirements;
    typedef struct VkSparseImageFormatProperties VkSparseImageFormatProperties;
    typedef struct VkSparseImageMemoryRequirements VkSparseImageMemoryRequirements;
    typedef struct VkMemoryType VkMemoryType;
    typedef struct VkMemoryHeap VkMemoryHeap;
    typedef struct VkMappedMemoryRange VkMappedMemoryRange;
    typedef struct VkFormatProperties VkFormatProperties;
    typedef struct VkImageFormatProperties VkImageFormatProperties;
    typedef struct VkDescriptorBufferInfo VkDescriptorBufferInfo;
    typedef struct VkDescriptorImageInfo VkDescriptorImageInfo;
    typedef struct VkWriteDescriptorSet VkWriteDescriptorSet;
    typedef struct VkCopyDescriptorSet VkCopyDescriptorSet;
    typedef struct VkBufferUsageFlags2CreateInfo VkBufferUsageFlags2CreateInfo;
    typedef struct VkBufferUsageFlags2CreateInfoKHR VkBufferUsageFlags2CreateInfoKHR;
    typedef struct VkBufferCreateInfo VkBufferCreateInfo;
    typedef struct VkBufferViewCreateInfo VkBufferViewCreateInfo;
    typedef struct VkImageSubresource VkImageSubresource;
    typedef struct VkImageSubresourceLayers VkImageSubresourceLayers;
    typedef struct VkImageSubresourceRange VkImageSubresourceRange;
    typedef struct VkMemoryBarrier VkMemoryBarrier;
    typedef struct VkBufferMemoryBarrier VkBufferMemoryBarrier;
    typedef struct VkImageMemoryBarrier VkImageMemoryBarrier;
    typedef struct VkImageCreateInfo VkImageCreateInfo;
    typedef struct VkSubresourceLayout VkSubresourceLayout;
    typedef struct VkImageViewCreateInfo VkImageViewCreateInfo;
    typedef struct VkBufferCopy VkBufferCopy;
    typedef struct VkSparseMemoryBind VkSparseMemoryBind;
    typedef struct VkSparseImageMemoryBind VkSparseImageMemoryBind;
    typedef struct VkSparseBufferMemoryBindInfo VkSparseBufferMemoryBindInfo;
    typedef struct VkSparseImageOpaqueMemoryBindInfo VkSparseImageOpaqueMemoryBindInfo;
    typedef struct VkSparseImageMemoryBindInfo VkSparseImageMemoryBindInfo;
    typedef struct VkBindSparseInfo VkBindSparseInfo;
    typedef struct VkImageCopy VkImageCopy;
    typedef struct VkImageBlit VkImageBlit;
    typedef struct VkBufferImageCopy VkBufferImageCopy;
    typedef struct VkStridedDeviceAddressRangeKHR VkStridedDeviceAddressRangeKHR;
    typedef struct VkCopyMemoryIndirectCommandKHR VkCopyMemoryIndirectCommandKHR;
    typedef struct VkCopyMemoryIndirectCommandNV VkCopyMemoryIndirectCommandNV;
    typedef struct VkCopyMemoryIndirectInfoKHR VkCopyMemoryIndirectInfoKHR;
    typedef struct VkCopyMemoryToImageIndirectCommandKHR VkCopyMemoryToImageIndirectCommandKHR;
    typedef struct VkCopyMemoryToImageIndirectCommandNV VkCopyMemoryToImageIndirectCommandNV;
    typedef struct VkCopyMemoryToImageIndirectInfoKHR VkCopyMemoryToImageIndirectInfoKHR;
    typedef struct VkImageResolve VkImageResolve;
    typedef struct VkShaderModuleCreateInfo VkShaderModuleCreateInfo;
    typedef struct VkDescriptorSetLayoutBinding VkDescriptorSetLayoutBinding;
    typedef struct VkDescriptorSetLayoutCreateInfo VkDescriptorSetLayoutCreateInfo;
    typedef struct VkDescriptorPoolSize VkDescriptorPoolSize;
    typedef struct VkDescriptorPoolCreateInfo VkDescriptorPoolCreateInfo;
    typedef struct VkDescriptorSetAllocateInfo VkDescriptorSetAllocateInfo;
    typedef struct VkSpecializationMapEntry VkSpecializationMapEntry;
    typedef struct VkSpecializationInfo VkSpecializationInfo;
    typedef struct VkPipelineShaderStageCreateInfo VkPipelineShaderStageCreateInfo;
    typedef struct VkComputePipelineCreateInfo VkComputePipelineCreateInfo;
    typedef struct VkComputePipelineIndirectBufferInfoNV VkComputePipelineIndirectBufferInfoNV;
    typedef struct VkPipelineCreateFlags2CreateInfo VkPipelineCreateFlags2CreateInfo;
    typedef struct VkPipelineCreateFlags2CreateInfoKHR VkPipelineCreateFlags2CreateInfoKHR;
    typedef struct VkVertexInputBindingDescription VkVertexInputBindingDescription;
    typedef struct VkVertexInputAttributeDescription VkVertexInputAttributeDescription;
    typedef struct VkPipelineVertexInputStateCreateInfo VkPipelineVertexInputStateCreateInfo;
    typedef struct VkPipelineInputAssemblyStateCreateInfo VkPipelineInputAssemblyStateCreateInfo;
    typedef struct VkPipelineTessellationStateCreateInfo VkPipelineTessellationStateCreateInfo;
    typedef struct VkPipelineViewportStateCreateInfo VkPipelineViewportStateCreateInfo;
    typedef struct VkPipelineRasterizationStateCreateInfo VkPipelineRasterizationStateCreateInfo;
    typedef struct VkPipelineMultisampleStateCreateInfo VkPipelineMultisampleStateCreateInfo;
    typedef struct VkPipelineColorBlendAttachmentState VkPipelineColorBlendAttachmentState;
    typedef struct VkPipelineColorBlendStateCreateInfo VkPipelineColorBlendStateCreateInfo;
    typedef struct VkPipelineDynamicStateCreateInfo VkPipelineDynamicStateCreateInfo;
    typedef struct VkStencilOpState VkStencilOpState;
    typedef struct VkPipelineDepthStencilStateCreateInfo VkPipelineDepthStencilStateCreateInfo;
    typedef struct VkGraphicsPipelineCreateInfo VkGraphicsPipelineCreateInfo;
    typedef struct VkPipelineCacheCreateInfo VkPipelineCacheCreateInfo;
    typedef struct VkPipelineCacheHeaderVersionOne VkPipelineCacheHeaderVersionOne;
    typedef struct VkPipelineCacheStageValidationIndexEntry VkPipelineCacheStageValidationIndexEntry;
    typedef struct VkPipelineCacheSafetyCriticalIndexEntry VkPipelineCacheSafetyCriticalIndexEntry;
    typedef struct VkPipelineCacheHeaderVersionSafetyCriticalOne VkPipelineCacheHeaderVersionSafetyCriticalOne;
    typedef struct VkPipelineCacheHeaderVersionDataGraphQCOM VkPipelineCacheHeaderVersionDataGraphQCOM;
    typedef struct VkPushConstantRange VkPushConstantRange;
    typedef struct VkPipelineBinaryCreateInfoKHR VkPipelineBinaryCreateInfoKHR;
    typedef struct VkPipelineBinaryHandlesInfoKHR VkPipelineBinaryHandlesInfoKHR;
    typedef struct VkPipelineBinaryDataKHR VkPipelineBinaryDataKHR;
    typedef struct VkPipelineBinaryKeysAndDataKHR VkPipelineBinaryKeysAndDataKHR;
    typedef struct VkPipelineBinaryKeyKHR VkPipelineBinaryKeyKHR;
    typedef struct VkPipelineBinaryInfoKHR VkPipelineBinaryInfoKHR;
    typedef struct VkReleaseCapturedPipelineDataInfoKHR VkReleaseCapturedPipelineDataInfoKHR;
    typedef struct VkPipelineBinaryDataInfoKHR VkPipelineBinaryDataInfoKHR;
    typedef struct VkPipelineCreateInfoKHR VkPipelineCreateInfoKHR;
    typedef struct VkPipelineLayoutCreateInfo VkPipelineLayoutCreateInfo;
    typedef struct VkSamplerCreateInfo VkSamplerCreateInfo;
    typedef struct VkCommandPoolCreateInfo VkCommandPoolCreateInfo;
    typedef struct VkCommandBufferAllocateInfo VkCommandBufferAllocateInfo;
    typedef struct VkCommandBufferInheritanceInfo VkCommandBufferInheritanceInfo;
    typedef struct VkCommandBufferBeginInfo VkCommandBufferBeginInfo;
    typedef struct VkRenderPassBeginInfo VkRenderPassBeginInfo;
    typedef union VkClearColorValue VkClearColorValue;
    typedef struct VkClearDepthStencilValue VkClearDepthStencilValue;
    typedef union VkClearValue VkClearValue;
    typedef struct VkClearAttachment VkClearAttachment;
    typedef struct VkAttachmentDescription VkAttachmentDescription;
    typedef struct VkAttachmentReference VkAttachmentReference;
    typedef struct VkSubpassDescription VkSubpassDescription;
    typedef struct VkSubpassDependency VkSubpassDependency;
    typedef struct VkRenderPassCreateInfo VkRenderPassCreateInfo;
    typedef struct VkEventCreateInfo VkEventCreateInfo;
    typedef struct VkFenceCreateInfo VkFenceCreateInfo;
    typedef struct VkPhysicalDeviceFeatures VkPhysicalDeviceFeatures;
    typedef struct VkPhysicalDeviceSparseProperties VkPhysicalDeviceSparseProperties;
    typedef struct VkPhysicalDeviceLimits VkPhysicalDeviceLimits;
    typedef struct VkSemaphoreCreateInfo VkSemaphoreCreateInfo;
    typedef struct VkQueryPoolCreateInfo VkQueryPoolCreateInfo;
    typedef struct VkFramebufferCreateInfo VkFramebufferCreateInfo;
    typedef struct VkDrawIndirectCommand VkDrawIndirectCommand;
    typedef struct VkDrawIndexedIndirectCommand VkDrawIndexedIndirectCommand;
    typedef struct VkDispatchIndirectCommand VkDispatchIndirectCommand;
    typedef struct VkMultiDrawInfoEXT VkMultiDrawInfoEXT;
    typedef struct VkMultiDrawIndexedInfoEXT VkMultiDrawIndexedInfoEXT;
    typedef struct VkSubmitInfo VkSubmitInfo;
    typedef struct VkDisplayPropertiesKHR VkDisplayPropertiesKHR;
    typedef struct VkDisplayPlanePropertiesKHR VkDisplayPlanePropertiesKHR;
    typedef struct VkDisplayModeParametersKHR VkDisplayModeParametersKHR;
    typedef struct VkDisplayModePropertiesKHR VkDisplayModePropertiesKHR;
    typedef struct VkDisplayModeCreateInfoKHR VkDisplayModeCreateInfoKHR;
    typedef struct VkDisplayPlaneCapabilitiesKHR VkDisplayPlaneCapabilitiesKHR;
    typedef struct VkDisplaySurfaceCreateInfoKHR VkDisplaySurfaceCreateInfoKHR;
    typedef struct VkDisplaySurfaceStereoCreateInfoNV VkDisplaySurfaceStereoCreateInfoNV;
    typedef struct VkDisplayPresentInfoKHR VkDisplayPresentInfoKHR;
    typedef struct VkSurfaceCapabilitiesKHR VkSurfaceCapabilitiesKHR;
    typedef struct VkAndroidSurfaceCreateInfoKHR VkAndroidSurfaceCreateInfoKHR;
    typedef struct VkViSurfaceCreateInfoNN VkViSurfaceCreateInfoNN;
    typedef struct VkWaylandSurfaceCreateInfoKHR VkWaylandSurfaceCreateInfoKHR;
    typedef struct VkUbmSurfaceCreateInfoSEC VkUbmSurfaceCreateInfoSEC;
    typedef struct VkWin32SurfaceCreateInfoKHR VkWin32SurfaceCreateInfoKHR;
    typedef struct VkXlibSurfaceCreateInfoKHR VkXlibSurfaceCreateInfoKHR;
    typedef struct VkXcbSurfaceCreateInfoKHR VkXcbSurfaceCreateInfoKHR;
    typedef struct VkDirectFBSurfaceCreateInfoEXT VkDirectFBSurfaceCreateInfoEXT;
    typedef struct VkImagePipeSurfaceCreateInfoFUCHSIA VkImagePipeSurfaceCreateInfoFUCHSIA;
    typedef struct VkStreamDescriptorSurfaceCreateInfoGGP VkStreamDescriptorSurfaceCreateInfoGGP;
    typedef struct VkScreenSurfaceCreateInfoQNX VkScreenSurfaceCreateInfoQNX;
    typedef struct VkSurfaceFormatKHR VkSurfaceFormatKHR;
    typedef struct VkSwapchainCreateInfoKHR VkSwapchainCreateInfoKHR;
    typedef struct VkPresentInfoKHR VkPresentInfoKHR;
    typedef struct VkDebugReportCallbackCreateInfoEXT VkDebugReportCallbackCreateInfoEXT;
    typedef struct VkValidationFlagsEXT VkValidationFlagsEXT;
    typedef struct VkValidationFeaturesEXT VkValidationFeaturesEXT;
    typedef struct VkLayerSettingsCreateInfoEXT VkLayerSettingsCreateInfoEXT;
    typedef struct VkLayerSettingEXT VkLayerSettingEXT;
    typedef struct VkApplicationParametersEXT VkApplicationParametersEXT;
    typedef struct VkPipelineRasterizationStateRasterizationOrderAMD VkPipelineRasterizationStateRasterizationOrderAMD;
    typedef struct VkDebugMarkerObjectNameInfoEXT VkDebugMarkerObjectNameInfoEXT;
    typedef struct VkDebugMarkerObjectTagInfoEXT VkDebugMarkerObjectTagInfoEXT;
    typedef struct VkDebugMarkerMarkerInfoEXT VkDebugMarkerMarkerInfoEXT;
    typedef struct VkDedicatedAllocationImageCreateInfoNV VkDedicatedAllocationImageCreateInfoNV;
    typedef struct VkDedicatedAllocationBufferCreateInfoNV VkDedicatedAllocationBufferCreateInfoNV;
    typedef struct VkDedicatedAllocationMemoryAllocateInfoNV VkDedicatedAllocationMemoryAllocateInfoNV;
    typedef struct VkExternalImageFormatPropertiesNV VkExternalImageFormatPropertiesNV;
    typedef struct VkExternalMemoryImageCreateInfoNV VkExternalMemoryImageCreateInfoNV;
    typedef struct VkExportMemoryAllocateInfoNV VkExportMemoryAllocateInfoNV;
    typedef struct VkImportMemoryWin32HandleInfoNV VkImportMemoryWin32HandleInfoNV;
    typedef struct VkExportMemoryWin32HandleInfoNV VkExportMemoryWin32HandleInfoNV;
    typedef struct VkExportMemorySciBufInfoNV VkExportMemorySciBufInfoNV;
    typedef struct VkImportMemorySciBufInfoNV VkImportMemorySciBufInfoNV;
    typedef struct VkMemoryGetSciBufInfoNV VkMemoryGetSciBufInfoNV;
    typedef struct VkMemorySciBufPropertiesNV VkMemorySciBufPropertiesNV;
    typedef struct VkPhysicalDeviceExternalMemorySciBufFeaturesNV VkPhysicalDeviceExternalMemorySciBufFeaturesNV;
    typedef struct VkPhysicalDeviceExternalSciBufFeaturesNV VkPhysicalDeviceExternalSciBufFeaturesNV;
    typedef struct VkWin32KeyedMutexAcquireReleaseInfoNV VkWin32KeyedMutexAcquireReleaseInfoNV;
    typedef struct VkPhysicalDeviceDeviceGeneratedCommandsFeaturesNV VkPhysicalDeviceDeviceGeneratedCommandsFeaturesNV;
    typedef struct VkPushConstantBankInfoNV VkPushConstantBankInfoNV;
    typedef struct VkPhysicalDevicePushConstantBankFeaturesNV VkPhysicalDevicePushConstantBankFeaturesNV;
    typedef struct VkPhysicalDevicePushConstantBankPropertiesNV VkPhysicalDevicePushConstantBankPropertiesNV;
    typedef struct VkPhysicalDeviceDeviceGeneratedCommandsComputeFeaturesNV VkPhysicalDeviceDeviceGeneratedCommandsComputeFeaturesNV;
    typedef struct VkDevicePrivateDataCreateInfo VkDevicePrivateDataCreateInfo;
    typedef struct VkDevicePrivateDataCreateInfoEXT VkDevicePrivateDataCreateInfoEXT;
    typedef struct VkPrivateDataSlotCreateInfo VkPrivateDataSlotCreateInfo;
    typedef struct VkPrivateDataSlotCreateInfoEXT VkPrivateDataSlotCreateInfoEXT;
    typedef struct VkPhysicalDevicePrivateDataFeatures VkPhysicalDevicePrivateDataFeatures;
    typedef struct VkPhysicalDevicePrivateDataFeaturesEXT VkPhysicalDevicePrivateDataFeaturesEXT;
    typedef struct VkPhysicalDeviceDeviceGeneratedCommandsPropertiesNV VkPhysicalDeviceDeviceGeneratedCommandsPropertiesNV;
    typedef struct VkPhysicalDeviceClusterAccelerationStructureFeaturesNV VkPhysicalDeviceClusterAccelerationStructureFeaturesNV;
    typedef struct VkPhysicalDeviceClusterAccelerationStructurePropertiesNV VkPhysicalDeviceClusterAccelerationStructurePropertiesNV;
    typedef struct VkStridedDeviceAddressNV VkStridedDeviceAddressNV;
    typedef struct VkRayTracingPipelineClusterAccelerationStructureCreateInfoNV VkRayTracingPipelineClusterAccelerationStructureCreateInfoNV;
    typedef struct VkClusterAccelerationStructureGeometryIndexAndGeometryFlagsNV VkClusterAccelerationStructureGeometryIndexAndGeometryFlagsNV;
    typedef struct VkClusterAccelerationStructureMoveObjectsInfoNV VkClusterAccelerationStructureMoveObjectsInfoNV;
    typedef struct VkClusterAccelerationStructureBuildClustersBottomLevelInfoNV VkClusterAccelerationStructureBuildClustersBottomLevelInfoNV;
    typedef struct VkClusterAccelerationStructureGetTemplateIndicesInfoNV VkClusterAccelerationStructureGetTemplateIndicesInfoNV;
    typedef struct VkClusterAccelerationStructureBuildTriangleClusterInfoNV VkClusterAccelerationStructureBuildTriangleClusterInfoNV;
    typedef struct VkClusterAccelerationStructureBuildTriangleClusterTemplateInfoNV VkClusterAccelerationStructureBuildTriangleClusterTemplateInfoNV;
    typedef struct VkClusterAccelerationStructureInstantiateClusterInfoNV VkClusterAccelerationStructureInstantiateClusterInfoNV;
    typedef struct VkClusterAccelerationStructureClustersBottomLevelInputNV VkClusterAccelerationStructureClustersBottomLevelInputNV;
    typedef struct VkClusterAccelerationStructureTriangleClusterInputNV VkClusterAccelerationStructureTriangleClusterInputNV;
    typedef struct VkClusterAccelerationStructureMoveObjectsInputNV VkClusterAccelerationStructureMoveObjectsInputNV;
    typedef union VkClusterAccelerationStructureOpInputNV VkClusterAccelerationStructureOpInputNV;
    typedef struct VkClusterAccelerationStructureInputInfoNV VkClusterAccelerationStructureInputInfoNV;
    typedef struct VkClusterAccelerationStructureCommandsInfoNV VkClusterAccelerationStructureCommandsInfoNV;
    typedef struct VkPhysicalDeviceMultiDrawPropertiesEXT VkPhysicalDeviceMultiDrawPropertiesEXT;
    typedef struct VkGraphicsShaderGroupCreateInfoNV VkGraphicsShaderGroupCreateInfoNV;
    typedef struct VkGraphicsPipelineShaderGroupsCreateInfoNV VkGraphicsPipelineShaderGroupsCreateInfoNV;
    typedef struct VkBindShaderGroupIndirectCommandNV VkBindShaderGroupIndirectCommandNV;
    typedef struct VkBindIndexBufferIndirectCommandNV VkBindIndexBufferIndirectCommandNV;
    typedef struct VkBindVertexBufferIndirectCommandNV VkBindVertexBufferIndirectCommandNV;
    typedef struct VkSetStateFlagsIndirectCommandNV VkSetStateFlagsIndirectCommandNV;
    typedef struct VkIndirectCommandsStreamNV VkIndirectCommandsStreamNV;
    typedef struct VkIndirectCommandsLayoutTokenNV VkIndirectCommandsLayoutTokenNV;
    typedef struct VkIndirectCommandsLayoutCreateInfoNV VkIndirectCommandsLayoutCreateInfoNV;
    typedef struct VkGeneratedCommandsInfoNV VkGeneratedCommandsInfoNV;
    typedef struct VkGeneratedCommandsMemoryRequirementsInfoNV VkGeneratedCommandsMemoryRequirementsInfoNV;
    typedef struct VkPipelineIndirectDeviceAddressInfoNV VkPipelineIndirectDeviceAddressInfoNV;
    typedef struct VkBindPipelineIndirectCommandNV VkBindPipelineIndirectCommandNV;
    typedef struct VkPhysicalDeviceFeatures2 VkPhysicalDeviceFeatures2;
    typedef struct VkPhysicalDeviceFeatures2KHR VkPhysicalDeviceFeatures2KHR;
    typedef struct VkPhysicalDeviceProperties2 VkPhysicalDeviceProperties2;
    typedef struct VkPhysicalDeviceProperties2KHR VkPhysicalDeviceProperties2KHR;
    typedef struct VkFormatProperties2 VkFormatProperties2;
    typedef struct VkFormatProperties2KHR VkFormatProperties2KHR;
    typedef struct VkImageFormatProperties2 VkImageFormatProperties2;
    typedef struct VkImageFormatProperties2KHR VkImageFormatProperties2KHR;
    typedef struct VkPhysicalDeviceImageFormatInfo2 VkPhysicalDeviceImageFormatInfo2;
    typedef struct VkPhysicalDeviceImageFormatInfo2KHR VkPhysicalDeviceImageFormatInfo2KHR;
    typedef struct VkQueueFamilyProperties2 VkQueueFamilyProperties2;
    typedef struct VkQueueFamilyProperties2KHR VkQueueFamilyProperties2KHR;
    typedef struct VkPhysicalDeviceMemoryProperties2 VkPhysicalDeviceMemoryProperties2;
    typedef struct VkPhysicalDeviceMemoryProperties2KHR VkPhysicalDeviceMemoryProperties2KHR;
    typedef struct VkSparseImageFormatProperties2 VkSparseImageFormatProperties2;
    typedef struct VkSparseImageFormatProperties2KHR VkSparseImageFormatProperties2KHR;
    typedef struct VkPhysicalDeviceSparseImageFormatInfo2 VkPhysicalDeviceSparseImageFormatInfo2;
    typedef struct VkPhysicalDeviceSparseImageFormatInfo2KHR VkPhysicalDeviceSparseImageFormatInfo2KHR;
    typedef struct VkPhysicalDevicePushDescriptorProperties VkPhysicalDevicePushDescriptorProperties;
    typedef struct VkPhysicalDevicePushDescriptorPropertiesKHR VkPhysicalDevicePushDescriptorPropertiesKHR;
    typedef struct VkConformanceVersion VkConformanceVersion;
    typedef struct VkConformanceVersionKHR VkConformanceVersionKHR;
    typedef struct VkPhysicalDeviceDriverProperties VkPhysicalDeviceDriverProperties;
    typedef struct VkPhysicalDeviceDriverPropertiesKHR VkPhysicalDeviceDriverPropertiesKHR;
    typedef struct VkPresentRegionsKHR VkPresentRegionsKHR;
    typedef struct VkPresentRegionKHR VkPresentRegionKHR;
    typedef struct VkRectLayerKHR VkRectLayerKHR;
    typedef struct VkPhysicalDeviceVariablePointersFeatures VkPhysicalDeviceVariablePointersFeatures;
    typedef struct VkPhysicalDeviceVariablePointersFeaturesKHR VkPhysicalDeviceVariablePointersFeaturesKHR;
    typedef struct VkPhysicalDeviceVariablePointerFeaturesKHR VkPhysicalDeviceVariablePointerFeaturesKHR;
    typedef struct VkPhysicalDeviceVariablePointerFeatures VkPhysicalDeviceVariablePointerFeatures;
    typedef struct VkExternalMemoryProperties VkExternalMemoryProperties;
    typedef struct VkExternalMemoryPropertiesKHR VkExternalMemoryPropertiesKHR;
    typedef struct VkPhysicalDeviceExternalImageFormatInfo VkPhysicalDeviceExternalImageFormatInfo;
    typedef struct VkPhysicalDeviceExternalImageFormatInfoKHR VkPhysicalDeviceExternalImageFormatInfoKHR;
    typedef struct VkExternalImageFormatProperties VkExternalImageFormatProperties;
    typedef struct VkExternalImageFormatPropertiesKHR VkExternalImageFormatPropertiesKHR;
    typedef struct VkPhysicalDeviceExternalBufferInfo VkPhysicalDeviceExternalBufferInfo;
    typedef struct VkPhysicalDeviceExternalBufferInfoKHR VkPhysicalDeviceExternalBufferInfoKHR;
    typedef struct VkExternalBufferProperties VkExternalBufferProperties;
    typedef struct VkExternalBufferPropertiesKHR VkExternalBufferPropertiesKHR;
    typedef struct VkPhysicalDeviceIDProperties VkPhysicalDeviceIDProperties;
    typedef struct VkPhysicalDeviceIDPropertiesKHR VkPhysicalDeviceIDPropertiesKHR;
    typedef struct VkExternalMemoryImageCreateInfo VkExternalMemoryImageCreateInfo;
    typedef struct VkExternalMemoryImageCreateInfoKHR VkExternalMemoryImageCreateInfoKHR;
    typedef struct VkExternalMemoryBufferCreateInfo VkExternalMemoryBufferCreateInfo;
    typedef struct VkExternalMemoryBufferCreateInfoKHR VkExternalMemoryBufferCreateInfoKHR;
    typedef struct VkExportMemoryAllocateInfo VkExportMemoryAllocateInfo;
    typedef struct VkExportMemoryAllocateInfoKHR VkExportMemoryAllocateInfoKHR;
    typedef struct VkImportMemoryWin32HandleInfoKHR VkImportMemoryWin32HandleInfoKHR;
    typedef struct VkExportMemoryWin32HandleInfoKHR VkExportMemoryWin32HandleInfoKHR;
    typedef struct VkImportMemoryZirconHandleInfoFUCHSIA VkImportMemoryZirconHandleInfoFUCHSIA;
    typedef struct VkMemoryZirconHandlePropertiesFUCHSIA VkMemoryZirconHandlePropertiesFUCHSIA;
    typedef struct VkMemoryGetZirconHandleInfoFUCHSIA VkMemoryGetZirconHandleInfoFUCHSIA;
    typedef struct VkMemoryWin32HandlePropertiesKHR VkMemoryWin32HandlePropertiesKHR;
    typedef struct VkMemoryGetWin32HandleInfoKHR VkMemoryGetWin32HandleInfoKHR;
    typedef struct VkImportMemoryFdInfoKHR VkImportMemoryFdInfoKHR;
    typedef struct VkMemoryFdPropertiesKHR VkMemoryFdPropertiesKHR;
    typedef struct VkMemoryGetFdInfoKHR VkMemoryGetFdInfoKHR;
    typedef struct VkWin32KeyedMutexAcquireReleaseInfoKHR VkWin32KeyedMutexAcquireReleaseInfoKHR;
    typedef struct VkImportMemoryMetalHandleInfoEXT VkImportMemoryMetalHandleInfoEXT;
    typedef struct VkMemoryMetalHandlePropertiesEXT VkMemoryMetalHandlePropertiesEXT;
    typedef struct VkMemoryGetMetalHandleInfoEXT VkMemoryGetMetalHandleInfoEXT;
    typedef struct VkPhysicalDeviceExternalSemaphoreInfo VkPhysicalDeviceExternalSemaphoreInfo;
    typedef struct VkPhysicalDeviceExternalSemaphoreInfoKHR VkPhysicalDeviceExternalSemaphoreInfoKHR;
    typedef struct VkExternalSemaphoreProperties VkExternalSemaphoreProperties;
    typedef struct VkExternalSemaphorePropertiesKHR VkExternalSemaphorePropertiesKHR;
    typedef struct VkExportSemaphoreCreateInfo VkExportSemaphoreCreateInfo;
    typedef struct VkExportSemaphoreCreateInfoKHR VkExportSemaphoreCreateInfoKHR;
    typedef struct VkImportSemaphoreWin32HandleInfoKHR VkImportSemaphoreWin32HandleInfoKHR;
    typedef struct VkExportSemaphoreWin32HandleInfoKHR VkExportSemaphoreWin32HandleInfoKHR;
    typedef struct VkD3D12FenceSubmitInfoKHR VkD3D12FenceSubmitInfoKHR;
    typedef struct VkSemaphoreGetWin32HandleInfoKHR VkSemaphoreGetWin32HandleInfoKHR;
    typedef struct VkImportSemaphoreFdInfoKHR VkImportSemaphoreFdInfoKHR;
    typedef struct VkSemaphoreGetFdInfoKHR VkSemaphoreGetFdInfoKHR;
    typedef struct VkImportSemaphoreZirconHandleInfoFUCHSIA VkImportSemaphoreZirconHandleInfoFUCHSIA;
    typedef struct VkSemaphoreGetZirconHandleInfoFUCHSIA VkSemaphoreGetZirconHandleInfoFUCHSIA;
    typedef struct VkPhysicalDeviceExternalFenceInfo VkPhysicalDeviceExternalFenceInfo;
    typedef struct VkPhysicalDeviceExternalFenceInfoKHR VkPhysicalDeviceExternalFenceInfoKHR;
    typedef struct VkExternalFenceProperties VkExternalFenceProperties;
    typedef struct VkExternalFencePropertiesKHR VkExternalFencePropertiesKHR;
    typedef struct VkExportFenceCreateInfo VkExportFenceCreateInfo;
    typedef struct VkExportFenceCreateInfoKHR VkExportFenceCreateInfoKHR;
    typedef struct VkImportFenceWin32HandleInfoKHR VkImportFenceWin32HandleInfoKHR;
    typedef struct VkExportFenceWin32HandleInfoKHR VkExportFenceWin32HandleInfoKHR;
    typedef struct VkFenceGetWin32HandleInfoKHR VkFenceGetWin32HandleInfoKHR;
    typedef struct VkImportFenceFdInfoKHR VkImportFenceFdInfoKHR;
    typedef struct VkFenceGetFdInfoKHR VkFenceGetFdInfoKHR;
    typedef struct VkExportFenceSciSyncInfoNV VkExportFenceSciSyncInfoNV;
    typedef struct VkImportFenceSciSyncInfoNV VkImportFenceSciSyncInfoNV;
    typedef struct VkFenceGetSciSyncInfoNV VkFenceGetSciSyncInfoNV;
    typedef struct VkExportSemaphoreSciSyncInfoNV VkExportSemaphoreSciSyncInfoNV;
    typedef struct VkImportSemaphoreSciSyncInfoNV VkImportSemaphoreSciSyncInfoNV;
    typedef struct VkSemaphoreGetSciSyncInfoNV VkSemaphoreGetSciSyncInfoNV;
    typedef struct VkSciSyncAttributesInfoNV VkSciSyncAttributesInfoNV;
    typedef struct VkPhysicalDeviceExternalSciSyncFeaturesNV VkPhysicalDeviceExternalSciSyncFeaturesNV;
    typedef struct VkPhysicalDeviceExternalSciSync2FeaturesNV VkPhysicalDeviceExternalSciSync2FeaturesNV;
    typedef struct VkSemaphoreSciSyncPoolCreateInfoNV VkSemaphoreSciSyncPoolCreateInfoNV;
    typedef struct VkSemaphoreSciSyncCreateInfoNV VkSemaphoreSciSyncCreateInfoNV;
    typedef struct VkDeviceSemaphoreSciSyncPoolReservationCreateInfoNV VkDeviceSemaphoreSciSyncPoolReservationCreateInfoNV;
    typedef struct VkPhysicalDeviceMultiviewFeatures VkPhysicalDeviceMultiviewFeatures;
    typedef struct VkPhysicalDeviceMultiviewFeaturesKHR VkPhysicalDeviceMultiviewFeaturesKHR;
    typedef struct VkPhysicalDeviceMultiviewProperties VkPhysicalDeviceMultiviewProperties;
    typedef struct VkPhysicalDeviceMultiviewPropertiesKHR VkPhysicalDeviceMultiviewPropertiesKHR;
    typedef struct VkRenderPassMultiviewCreateInfo VkRenderPassMultiviewCreateInfo;
    typedef struct VkRenderPassMultiviewCreateInfoKHR VkRenderPassMultiviewCreateInfoKHR;
    typedef struct VkSurfaceCapabilities2EXT VkSurfaceCapabilities2EXT;
    typedef struct VkDisplayPowerInfoEXT VkDisplayPowerInfoEXT;
    typedef struct VkDeviceEventInfoEXT VkDeviceEventInfoEXT;
    typedef struct VkDisplayEventInfoEXT VkDisplayEventInfoEXT;
    typedef struct VkSwapchainCounterCreateInfoEXT VkSwapchainCounterCreateInfoEXT;
    typedef struct VkPhysicalDeviceGroupProperties VkPhysicalDeviceGroupProperties;
    typedef struct VkPhysicalDeviceGroupPropertiesKHR VkPhysicalDeviceGroupPropertiesKHR;
    typedef struct VkMemoryAllocateFlagsInfo VkMemoryAllocateFlagsInfo;
    typedef struct VkMemoryAllocateFlagsInfoKHR VkMemoryAllocateFlagsInfoKHR;
    typedef struct VkBindBufferMemoryInfo VkBindBufferMemoryInfo;
    typedef struct VkBindBufferMemoryInfoKHR VkBindBufferMemoryInfoKHR;
    typedef struct VkBindBufferMemoryDeviceGroupInfo VkBindBufferMemoryDeviceGroupInfo;
    typedef struct VkBindBufferMemoryDeviceGroupInfoKHR VkBindBufferMemoryDeviceGroupInfoKHR;
    typedef struct VkBindImageMemoryInfo VkBindImageMemoryInfo;
    typedef struct VkBindImageMemoryInfoKHR VkBindImageMemoryInfoKHR;
    typedef struct VkBindImageMemoryDeviceGroupInfo VkBindImageMemoryDeviceGroupInfo;
    typedef struct VkBindImageMemoryDeviceGroupInfoKHR VkBindImageMemoryDeviceGroupInfoKHR;
    typedef struct VkDeviceGroupRenderPassBeginInfo VkDeviceGroupRenderPassBeginInfo;
    typedef struct VkDeviceGroupRenderPassBeginInfoKHR VkDeviceGroupRenderPassBeginInfoKHR;
    typedef struct VkDeviceGroupCommandBufferBeginInfo VkDeviceGroupCommandBufferBeginInfo;
    typedef struct VkDeviceGroupCommandBufferBeginInfoKHR VkDeviceGroupCommandBufferBeginInfoKHR;
    typedef struct VkDeviceGroupSubmitInfo VkDeviceGroupSubmitInfo;
    typedef struct VkDeviceGroupSubmitInfoKHR VkDeviceGroupSubmitInfoKHR;
    typedef struct VkDeviceGroupBindSparseInfo VkDeviceGroupBindSparseInfo;
    typedef struct VkDeviceGroupBindSparseInfoKHR VkDeviceGroupBindSparseInfoKHR;
    typedef struct VkDeviceGroupPresentCapabilitiesKHR VkDeviceGroupPresentCapabilitiesKHR;
    typedef struct VkImageSwapchainCreateInfoKHR VkImageSwapchainCreateInfoKHR;
    typedef struct VkBindImageMemorySwapchainInfoKHR VkBindImageMemorySwapchainInfoKHR;
    typedef struct VkAcquireNextImageInfoKHR VkAcquireNextImageInfoKHR;
    typedef struct VkDeviceGroupPresentInfoKHR VkDeviceGroupPresentInfoKHR;
    typedef struct VkDeviceGroupDeviceCreateInfo VkDeviceGroupDeviceCreateInfo;
    typedef struct VkDeviceGroupDeviceCreateInfoKHR VkDeviceGroupDeviceCreateInfoKHR;
    typedef struct VkDeviceGroupSwapchainCreateInfoKHR VkDeviceGroupSwapchainCreateInfoKHR;
    typedef struct VkDescriptorUpdateTemplateEntry VkDescriptorUpdateTemplateEntry;
    typedef struct VkDescriptorUpdateTemplateEntryKHR VkDescriptorUpdateTemplateEntryKHR;
    typedef struct VkDescriptorUpdateTemplateCreateInfo VkDescriptorUpdateTemplateCreateInfo;
    typedef struct VkDescriptorUpdateTemplateCreateInfoKHR VkDescriptorUpdateTemplateCreateInfoKHR;
    typedef struct VkXYColorEXT VkXYColorEXT;
    typedef struct VkPhysicalDevicePresentIdFeaturesKHR VkPhysicalDevicePresentIdFeaturesKHR;
    typedef struct VkPresentIdKHR VkPresentIdKHR;
    typedef struct VkPhysicalDevicePresentId2FeaturesKHR VkPhysicalDevicePresentId2FeaturesKHR;
    typedef struct VkPresentId2KHR VkPresentId2KHR;
    typedef struct VkPresentWait2InfoKHR VkPresentWait2InfoKHR;
    typedef struct VkPhysicalDevicePresentWaitFeaturesKHR VkPhysicalDevicePresentWaitFeaturesKHR;
    typedef struct VkPhysicalDevicePresentWait2FeaturesKHR VkPhysicalDevicePresentWait2FeaturesKHR;
    typedef struct VkPhysicalDevicePresentTimingFeaturesEXT VkPhysicalDevicePresentTimingFeaturesEXT;
    typedef struct VkPresentTimingSurfaceCapabilitiesEXT VkPresentTimingSurfaceCapabilitiesEXT;
    typedef struct VkSwapchainTimingPropertiesEXT VkSwapchainTimingPropertiesEXT;
    typedef struct VkSwapchainTimeDomainPropertiesEXT VkSwapchainTimeDomainPropertiesEXT;
    typedef struct VkPresentStageTimeEXT VkPresentStageTimeEXT;
    typedef struct VkPastPresentationTimingInfoEXT VkPastPresentationTimingInfoEXT;
    typedef struct VkPastPresentationTimingPropertiesEXT VkPastPresentationTimingPropertiesEXT;
    typedef struct VkPastPresentationTimingEXT VkPastPresentationTimingEXT;
    typedef struct VkPresentTimingsInfoEXT VkPresentTimingsInfoEXT;
    typedef struct VkPresentTimingInfoEXT VkPresentTimingInfoEXT;
    typedef struct VkSwapchainCalibratedTimestampInfoEXT VkSwapchainCalibratedTimestampInfoEXT;
    typedef struct VkHdrMetadataEXT VkHdrMetadataEXT;
    typedef struct VkHdrVividDynamicMetadataHUAWEI VkHdrVividDynamicMetadataHUAWEI;
    typedef struct VkDisplayNativeHdrSurfaceCapabilitiesAMD VkDisplayNativeHdrSurfaceCapabilitiesAMD;
    typedef struct VkSwapchainDisplayNativeHdrCreateInfoAMD VkSwapchainDisplayNativeHdrCreateInfoAMD;
    typedef struct VkRefreshCycleDurationGOOGLE VkRefreshCycleDurationGOOGLE;
    typedef struct VkPastPresentationTimingGOOGLE VkPastPresentationTimingGOOGLE;
    typedef struct VkPresentTimesInfoGOOGLE VkPresentTimesInfoGOOGLE;
    typedef struct VkPresentTimeGOOGLE VkPresentTimeGOOGLE;
    typedef struct VkIOSSurfaceCreateInfoMVK VkIOSSurfaceCreateInfoMVK;
    typedef struct VkMacOSSurfaceCreateInfoMVK VkMacOSSurfaceCreateInfoMVK;
    typedef struct VkMetalSurfaceCreateInfoEXT VkMetalSurfaceCreateInfoEXT;
    typedef struct VkViewportWScalingNV VkViewportWScalingNV;
    typedef struct VkPipelineViewportWScalingStateCreateInfoNV VkPipelineViewportWScalingStateCreateInfoNV;
    typedef struct VkViewportSwizzleNV VkViewportSwizzleNV;
    typedef struct VkPipelineViewportSwizzleStateCreateInfoNV VkPipelineViewportSwizzleStateCreateInfoNV;
    typedef struct VkPhysicalDeviceDiscardRectanglePropertiesEXT VkPhysicalDeviceDiscardRectanglePropertiesEXT;
    typedef struct VkPipelineDiscardRectangleStateCreateInfoEXT VkPipelineDiscardRectangleStateCreateInfoEXT;
    typedef struct VkPhysicalDeviceMultiviewPerViewAttributesPropertiesNVX VkPhysicalDeviceMultiviewPerViewAttributesPropertiesNVX;
    typedef struct VkInputAttachmentAspectReference VkInputAttachmentAspectReference;
    typedef struct VkInputAttachmentAspectReferenceKHR VkInputAttachmentAspectReferenceKHR;
    typedef struct VkRenderPassInputAttachmentAspectCreateInfo VkRenderPassInputAttachmentAspectCreateInfo;
    typedef struct VkRenderPassInputAttachmentAspectCreateInfoKHR VkRenderPassInputAttachmentAspectCreateInfoKHR;
    typedef struct VkPhysicalDeviceSurfaceInfo2KHR VkPhysicalDeviceSurfaceInfo2KHR;
    typedef struct VkSurfaceCapabilities2KHR VkSurfaceCapabilities2KHR;
    typedef struct VkSurfaceFormat2KHR VkSurfaceFormat2KHR;
    typedef struct VkDisplayProperties2KHR VkDisplayProperties2KHR;
    typedef struct VkDisplayPlaneProperties2KHR VkDisplayPlaneProperties2KHR;
    typedef struct VkDisplayModeProperties2KHR VkDisplayModeProperties2KHR;
    typedef struct VkDisplayModeStereoPropertiesNV VkDisplayModeStereoPropertiesNV;
    typedef struct VkDisplayPlaneInfo2KHR VkDisplayPlaneInfo2KHR;
    typedef struct VkDisplayPlaneCapabilities2KHR VkDisplayPlaneCapabilities2KHR;
    typedef struct VkSharedPresentSurfaceCapabilitiesKHR VkSharedPresentSurfaceCapabilitiesKHR;
    typedef struct VkPhysicalDevice16BitStorageFeatures VkPhysicalDevice16BitStorageFeatures;
    typedef struct VkPhysicalDevice16BitStorageFeaturesKHR VkPhysicalDevice16BitStorageFeaturesKHR;
    typedef struct VkPhysicalDeviceSubgroupProperties VkPhysicalDeviceSubgroupProperties;
    typedef struct VkPhysicalDeviceShaderSubgroupExtendedTypesFeatures VkPhysicalDeviceShaderSubgroupExtendedTypesFeatures;
    typedef struct VkPhysicalDeviceShaderSubgroupExtendedTypesFeaturesKHR VkPhysicalDeviceShaderSubgroupExtendedTypesFeaturesKHR;
    typedef struct VkBufferMemoryRequirementsInfo2 VkBufferMemoryRequirementsInfo2;
    typedef struct VkBufferMemoryRequirementsInfo2KHR VkBufferMemoryRequirementsInfo2KHR;
    typedef struct VkDeviceBufferMemoryRequirements VkDeviceBufferMemoryRequirements;
    typedef struct VkDeviceBufferMemoryRequirementsKHR VkDeviceBufferMemoryRequirementsKHR;
    typedef struct VkImageMemoryRequirementsInfo2 VkImageMemoryRequirementsInfo2;
    typedef struct VkImageMemoryRequirementsInfo2KHR VkImageMemoryRequirementsInfo2KHR;
    typedef struct VkImageSparseMemoryRequirementsInfo2 VkImageSparseMemoryRequirementsInfo2;
    typedef struct VkImageSparseMemoryRequirementsInfo2KHR VkImageSparseMemoryRequirementsInfo2KHR;
    typedef struct VkDeviceImageMemoryRequirements VkDeviceImageMemoryRequirements;
    typedef struct VkDeviceImageMemoryRequirementsKHR VkDeviceImageMemoryRequirementsKHR;
    typedef struct VkMemoryRequirements2 VkMemoryRequirements2;
    typedef struct VkMemoryRequirements2KHR VkMemoryRequirements2KHR;
    typedef struct VkSparseImageMemoryRequirements2 VkSparseImageMemoryRequirements2;
    typedef struct VkSparseImageMemoryRequirements2KHR VkSparseImageMemoryRequirements2KHR;
    typedef struct VkPhysicalDevicePointClippingProperties VkPhysicalDevicePointClippingProperties;
    typedef struct VkPhysicalDevicePointClippingPropertiesKHR VkPhysicalDevicePointClippingPropertiesKHR;
    typedef struct VkMemoryDedicatedRequirements VkMemoryDedicatedRequirements;
    typedef struct VkMemoryDedicatedRequirementsKHR VkMemoryDedicatedRequirementsKHR;
    typedef struct VkMemoryDedicatedAllocateInfo VkMemoryDedicatedAllocateInfo;
    typedef struct VkMemoryDedicatedAllocateInfoKHR VkMemoryDedicatedAllocateInfoKHR;
    typedef struct VkImageViewUsageCreateInfo VkImageViewUsageCreateInfo;
    typedef struct VkImageViewSlicedCreateInfoEXT VkImageViewSlicedCreateInfoEXT;
    typedef struct VkImageViewUsageCreateInfoKHR VkImageViewUsageCreateInfoKHR;
    typedef struct VkPipelineTessellationDomainOriginStateCreateInfo VkPipelineTessellationDomainOriginStateCreateInfo;
    typedef struct VkPipelineTessellationDomainOriginStateCreateInfoKHR VkPipelineTessellationDomainOriginStateCreateInfoKHR;
    typedef struct VkSamplerYcbcrConversionInfo VkSamplerYcbcrConversionInfo;
    typedef struct VkSamplerYcbcrConversionInfoKHR VkSamplerYcbcrConversionInfoKHR;
    typedef struct VkSamplerYcbcrConversionCreateInfo VkSamplerYcbcrConversionCreateInfo;
    typedef struct VkSamplerYcbcrConversionCreateInfoKHR VkSamplerYcbcrConversionCreateInfoKHR;
    typedef struct VkBindImagePlaneMemoryInfo VkBindImagePlaneMemoryInfo;
    typedef struct VkBindImagePlaneMemoryInfoKHR VkBindImagePlaneMemoryInfoKHR;
    typedef struct VkImagePlaneMemoryRequirementsInfo VkImagePlaneMemoryRequirementsInfo;
    typedef struct VkImagePlaneMemoryRequirementsInfoKHR VkImagePlaneMemoryRequirementsInfoKHR;
    typedef struct VkPhysicalDeviceSamplerYcbcrConversionFeatures VkPhysicalDeviceSamplerYcbcrConversionFeatures;
    typedef struct VkPhysicalDeviceSamplerYcbcrConversionFeaturesKHR VkPhysicalDeviceSamplerYcbcrConversionFeaturesKHR;
    typedef struct VkSamplerYcbcrConversionImageFormatProperties VkSamplerYcbcrConversionImageFormatProperties;
    typedef struct VkSamplerYcbcrConversionImageFormatPropertiesKHR VkSamplerYcbcrConversionImageFormatPropertiesKHR;
    typedef struct VkTextureLODGatherFormatPropertiesAMD VkTextureLODGatherFormatPropertiesAMD;
    typedef struct VkConditionalRenderingBeginInfoEXT VkConditionalRenderingBeginInfoEXT;
    typedef struct VkProtectedSubmitInfo VkProtectedSubmitInfo;
    typedef struct VkPhysicalDeviceProtectedMemoryFeatures VkPhysicalDeviceProtectedMemoryFeatures;
    typedef struct VkPhysicalDeviceProtectedMemoryProperties VkPhysicalDeviceProtectedMemoryProperties;
    typedef struct VkDeviceQueueInfo2 VkDeviceQueueInfo2;
    typedef struct VkPipelineCoverageToColorStateCreateInfoNV VkPipelineCoverageToColorStateCreateInfoNV;
    typedef struct VkPhysicalDeviceSamplerFilterMinmaxProperties VkPhysicalDeviceSamplerFilterMinmaxProperties;
    typedef struct VkPhysicalDeviceSamplerFilterMinmaxPropertiesEXT VkPhysicalDeviceSamplerFilterMinmaxPropertiesEXT;
    typedef struct VkSampleLocationEXT VkSampleLocationEXT;
    typedef struct VkSampleLocationsInfoEXT VkSampleLocationsInfoEXT;
    typedef struct VkAttachmentSampleLocationsEXT VkAttachmentSampleLocationsEXT;
    typedef struct VkSubpassSampleLocationsEXT VkSubpassSampleLocationsEXT;
    typedef struct VkRenderPassSampleLocationsBeginInfoEXT VkRenderPassSampleLocationsBeginInfoEXT;
    typedef struct VkPipelineSampleLocationsStateCreateInfoEXT VkPipelineSampleLocationsStateCreateInfoEXT;
    typedef struct VkPhysicalDeviceSampleLocationsPropertiesEXT VkPhysicalDeviceSampleLocationsPropertiesEXT;
    typedef struct VkMultisamplePropertiesEXT VkMultisamplePropertiesEXT;
    typedef struct VkSamplerReductionModeCreateInfo VkSamplerReductionModeCreateInfo;
    typedef struct VkSamplerReductionModeCreateInfoEXT VkSamplerReductionModeCreateInfoEXT;
    typedef struct VkPhysicalDeviceBlendOperationAdvancedFeaturesEXT VkPhysicalDeviceBlendOperationAdvancedFeaturesEXT;
    typedef struct VkPhysicalDeviceMultiDrawFeaturesEXT VkPhysicalDeviceMultiDrawFeaturesEXT;
    typedef struct VkPhysicalDeviceBlendOperationAdvancedPropertiesEXT VkPhysicalDeviceBlendOperationAdvancedPropertiesEXT;
    typedef struct VkPipelineColorBlendAdvancedStateCreateInfoEXT VkPipelineColorBlendAdvancedStateCreateInfoEXT;
    typedef struct VkPhysicalDeviceInlineUniformBlockFeatures VkPhysicalDeviceInlineUniformBlockFeatures;
    typedef struct VkPhysicalDeviceInlineUniformBlockFeaturesEXT VkPhysicalDeviceInlineUniformBlockFeaturesEXT;
    typedef struct VkPhysicalDeviceInlineUniformBlockProperties VkPhysicalDeviceInlineUniformBlockProperties;
    typedef struct VkPhysicalDeviceInlineUniformBlockPropertiesEXT VkPhysicalDeviceInlineUniformBlockPropertiesEXT;
    typedef struct VkWriteDescriptorSetInlineUniformBlock VkWriteDescriptorSetInlineUniformBlock;
    typedef struct VkWriteDescriptorSetInlineUniformBlockEXT VkWriteDescriptorSetInlineUniformBlockEXT;
    typedef struct VkDescriptorPoolInlineUniformBlockCreateInfo VkDescriptorPoolInlineUniformBlockCreateInfo;
    typedef struct VkDescriptorPoolInlineUniformBlockCreateInfoEXT VkDescriptorPoolInlineUniformBlockCreateInfoEXT;
    typedef struct VkPipelineCoverageModulationStateCreateInfoNV VkPipelineCoverageModulationStateCreateInfoNV;
    typedef struct VkImageFormatListCreateInfo VkImageFormatListCreateInfo;
    typedef struct VkImageFormatListCreateInfoKHR VkImageFormatListCreateInfoKHR;
    typedef struct VkValidationCacheCreateInfoEXT VkValidationCacheCreateInfoEXT;
    typedef struct VkShaderModuleValidationCacheCreateInfoEXT VkShaderModuleValidationCacheCreateInfoEXT;
    typedef struct VkPhysicalDeviceMaintenance3Properties VkPhysicalDeviceMaintenance3Properties;
    typedef struct VkPhysicalDeviceMaintenance3PropertiesKHR VkPhysicalDeviceMaintenance3PropertiesKHR;
    typedef struct VkPhysicalDeviceMaintenance4Features VkPhysicalDeviceMaintenance4Features;
    typedef struct VkPhysicalDeviceMaintenance4FeaturesKHR VkPhysicalDeviceMaintenance4FeaturesKHR;
    typedef struct VkPhysicalDeviceMaintenance4Properties VkPhysicalDeviceMaintenance4Properties;
    typedef struct VkPhysicalDeviceMaintenance4PropertiesKHR VkPhysicalDeviceMaintenance4PropertiesKHR;
    typedef struct VkPhysicalDeviceMaintenance5Features VkPhysicalDeviceMaintenance5Features;
    typedef struct VkPhysicalDeviceMaintenance5FeaturesKHR VkPhysicalDeviceMaintenance5FeaturesKHR;
    typedef struct VkPhysicalDeviceMaintenance5Properties VkPhysicalDeviceMaintenance5Properties;
    typedef struct VkPhysicalDeviceMaintenance5PropertiesKHR VkPhysicalDeviceMaintenance5PropertiesKHR;
    typedef struct VkPhysicalDeviceMaintenance6Features VkPhysicalDeviceMaintenance6Features;
    typedef struct VkPhysicalDeviceMaintenance6FeaturesKHR VkPhysicalDeviceMaintenance6FeaturesKHR;
    typedef struct VkPhysicalDeviceMaintenance6Properties VkPhysicalDeviceMaintenance6Properties;
    typedef struct VkPhysicalDeviceMaintenance6PropertiesKHR VkPhysicalDeviceMaintenance6PropertiesKHR;
    typedef struct VkPhysicalDeviceMaintenance7FeaturesKHR VkPhysicalDeviceMaintenance7FeaturesKHR;
    typedef struct VkPhysicalDeviceMaintenance7PropertiesKHR VkPhysicalDeviceMaintenance7PropertiesKHR;
    typedef struct VkPhysicalDeviceLayeredApiPropertiesListKHR VkPhysicalDeviceLayeredApiPropertiesListKHR;
    typedef struct VkPhysicalDeviceLayeredApiPropertiesKHR VkPhysicalDeviceLayeredApiPropertiesKHR;
    typedef struct VkPhysicalDeviceLayeredApiVulkanPropertiesKHR VkPhysicalDeviceLayeredApiVulkanPropertiesKHR;
    typedef struct VkPhysicalDeviceMaintenance8FeaturesKHR VkPhysicalDeviceMaintenance8FeaturesKHR;
    typedef struct VkPhysicalDeviceMaintenance9FeaturesKHR VkPhysicalDeviceMaintenance9FeaturesKHR;
    typedef struct VkPhysicalDeviceMaintenance9PropertiesKHR VkPhysicalDeviceMaintenance9PropertiesKHR;
    typedef struct VkPhysicalDeviceMaintenance10PropertiesKHR VkPhysicalDeviceMaintenance10PropertiesKHR;
    typedef struct VkPhysicalDeviceMaintenance10FeaturesKHR VkPhysicalDeviceMaintenance10FeaturesKHR;
    typedef struct VkQueueFamilyOwnershipTransferPropertiesKHR VkQueueFamilyOwnershipTransferPropertiesKHR;
    typedef struct VkRenderingAreaInfo VkRenderingAreaInfo;
    typedef struct VkRenderingAreaInfoKHR VkRenderingAreaInfoKHR;
    typedef struct VkDescriptorSetLayoutSupport VkDescriptorSetLayoutSupport;
    typedef struct VkDescriptorSetLayoutSupportKHR VkDescriptorSetLayoutSupportKHR;
    typedef struct VkPhysicalDeviceShaderDrawParametersFeatures VkPhysicalDeviceShaderDrawParametersFeatures;
    typedef struct VkPhysicalDeviceShaderDrawParameterFeatures VkPhysicalDeviceShaderDrawParameterFeatures;
    typedef struct VkPhysicalDeviceShaderFloat16Int8Features VkPhysicalDeviceShaderFloat16Int8Features;
    typedef struct VkPhysicalDeviceShaderFloat16Int8FeaturesKHR VkPhysicalDeviceShaderFloat16Int8FeaturesKHR;
    typedef struct VkPhysicalDeviceFloat16Int8FeaturesKHR VkPhysicalDeviceFloat16Int8FeaturesKHR;
    typedef struct VkPhysicalDeviceFloatControlsProperties VkPhysicalDeviceFloatControlsProperties;
    typedef struct VkPhysicalDeviceFloatControlsPropertiesKHR VkPhysicalDeviceFloatControlsPropertiesKHR;
    typedef struct VkPhysicalDeviceHostQueryResetFeatures VkPhysicalDeviceHostQueryResetFeatures;
    typedef struct VkPhysicalDeviceHostQueryResetFeaturesEXT VkPhysicalDeviceHostQueryResetFeaturesEXT;
    typedef struct VkNativeBufferUsage2ANDROID VkNativeBufferUsage2ANDROID;
    typedef struct VkNativeBufferANDROID VkNativeBufferANDROID;
    typedef struct VkSwapchainImageCreateInfoANDROID VkSwapchainImageCreateInfoANDROID;
    typedef struct VkPhysicalDevicePresentationPropertiesANDROID VkPhysicalDevicePresentationPropertiesANDROID;
    typedef struct VkShaderResourceUsageAMD VkShaderResourceUsageAMD;
    typedef struct VkShaderStatisticsInfoAMD VkShaderStatisticsInfoAMD;
    typedef struct VkDeviceQueueGlobalPriorityCreateInfo VkDeviceQueueGlobalPriorityCreateInfo;
    typedef struct VkDeviceQueueGlobalPriorityCreateInfoKHR VkDeviceQueueGlobalPriorityCreateInfoKHR;
    typedef struct VkDeviceQueueGlobalPriorityCreateInfoEXT VkDeviceQueueGlobalPriorityCreateInfoEXT;
    typedef struct VkPhysicalDeviceGlobalPriorityQueryFeatures VkPhysicalDeviceGlobalPriorityQueryFeatures;
    typedef struct VkPhysicalDeviceGlobalPriorityQueryFeaturesKHR VkPhysicalDeviceGlobalPriorityQueryFeaturesKHR;
    typedef struct VkPhysicalDeviceGlobalPriorityQueryFeaturesEXT VkPhysicalDeviceGlobalPriorityQueryFeaturesEXT;
    typedef struct VkQueueFamilyGlobalPriorityProperties VkQueueFamilyGlobalPriorityProperties;
    typedef struct VkQueueFamilyGlobalPriorityPropertiesKHR VkQueueFamilyGlobalPriorityPropertiesKHR;
    typedef struct VkQueueFamilyGlobalPriorityPropertiesEXT VkQueueFamilyGlobalPriorityPropertiesEXT;
    typedef struct VkDebugUtilsObjectNameInfoEXT VkDebugUtilsObjectNameInfoEXT;
    typedef struct VkDebugUtilsObjectTagInfoEXT VkDebugUtilsObjectTagInfoEXT;
    typedef struct VkDebugUtilsLabelEXT VkDebugUtilsLabelEXT;
    typedef struct VkDebugUtilsMessengerCreateInfoEXT VkDebugUtilsMessengerCreateInfoEXT;
    typedef struct VkDebugUtilsMessengerCallbackDataEXT VkDebugUtilsMessengerCallbackDataEXT;
    typedef struct VkPhysicalDeviceDeviceMemoryReportFeaturesEXT VkPhysicalDeviceDeviceMemoryReportFeaturesEXT;
    typedef struct VkDeviceDeviceMemoryReportCreateInfoEXT VkDeviceDeviceMemoryReportCreateInfoEXT;
    typedef struct VkDeviceMemoryReportCallbackDataEXT VkDeviceMemoryReportCallbackDataEXT;
    typedef struct VkImportMemoryHostPointerInfoEXT VkImportMemoryHostPointerInfoEXT;
    typedef struct VkMemoryHostPointerPropertiesEXT VkMemoryHostPointerPropertiesEXT;
    typedef struct VkPhysicalDeviceExternalMemoryHostPropertiesEXT VkPhysicalDeviceExternalMemoryHostPropertiesEXT;
    typedef struct VkPhysicalDeviceConservativeRasterizationPropertiesEXT VkPhysicalDeviceConservativeRasterizationPropertiesEXT;
    typedef struct VkCalibratedTimestampInfoKHR VkCalibratedTimestampInfoKHR;
    typedef struct VkCalibratedTimestampInfoEXT VkCalibratedTimestampInfoEXT;
    typedef struct VkPhysicalDeviceShaderCorePropertiesAMD VkPhysicalDeviceShaderCorePropertiesAMD;
    typedef struct VkPhysicalDeviceShaderCoreProperties2AMD VkPhysicalDeviceShaderCoreProperties2AMD;
    typedef struct VkPipelineRasterizationConservativeStateCreateInfoEXT VkPipelineRasterizationConservativeStateCreateInfoEXT;
    typedef struct VkPhysicalDeviceDescriptorIndexingFeatures VkPhysicalDeviceDescriptorIndexingFeatures;
    typedef struct VkPhysicalDeviceDescriptorIndexingFeaturesEXT VkPhysicalDeviceDescriptorIndexingFeaturesEXT;
    typedef struct VkPhysicalDeviceDescriptorIndexingProperties VkPhysicalDeviceDescriptorIndexingProperties;
    typedef struct VkPhysicalDeviceDescriptorIndexingPropertiesEXT VkPhysicalDeviceDescriptorIndexingPropertiesEXT;
    typedef struct VkDescriptorSetLayoutBindingFlagsCreateInfo VkDescriptorSetLayoutBindingFlagsCreateInfo;
    typedef struct VkDescriptorSetLayoutBindingFlagsCreateInfoEXT VkDescriptorSetLayoutBindingFlagsCreateInfoEXT;
    typedef struct VkDescriptorSetVariableDescriptorCountAllocateInfo VkDescriptorSetVariableDescriptorCountAllocateInfo;
    typedef struct VkDescriptorSetVariableDescriptorCountAllocateInfoEXT VkDescriptorSetVariableDescriptorCountAllocateInfoEXT;
    typedef struct VkDescriptorSetVariableDescriptorCountLayoutSupport VkDescriptorSetVariableDescriptorCountLayoutSupport;
    typedef struct VkDescriptorSetVariableDescriptorCountLayoutSupportEXT VkDescriptorSetVariableDescriptorCountLayoutSupportEXT;
    typedef struct VkAttachmentDescription2 VkAttachmentDescription2;
    typedef struct VkAttachmentDescription2KHR VkAttachmentDescription2KHR;
    typedef struct VkAttachmentReference2 VkAttachmentReference2;
    typedef struct VkAttachmentReference2KHR VkAttachmentReference2KHR;
    typedef struct VkSubpassDescription2 VkSubpassDescription2;
    typedef struct VkSubpassDescription2KHR VkSubpassDescription2KHR;
    typedef struct VkSubpassDependency2 VkSubpassDependency2;
    typedef struct VkSubpassDependency2KHR VkSubpassDependency2KHR;
    typedef struct VkRenderPassCreateInfo2 VkRenderPassCreateInfo2;
    typedef struct VkRenderPassCreateInfo2KHR VkRenderPassCreateInfo2KHR;
    typedef struct VkSubpassBeginInfo VkSubpassBeginInfo;
    typedef struct VkSubpassBeginInfoKHR VkSubpassBeginInfoKHR;
    typedef struct VkSubpassEndInfo VkSubpassEndInfo;
    typedef struct VkSubpassEndInfoKHR VkSubpassEndInfoKHR;
    typedef struct VkPhysicalDeviceTimelineSemaphoreFeatures VkPhysicalDeviceTimelineSemaphoreFeatures;
    typedef struct VkPhysicalDeviceTimelineSemaphoreFeaturesKHR VkPhysicalDeviceTimelineSemaphoreFeaturesKHR;
    typedef struct VkPhysicalDeviceTimelineSemaphoreProperties VkPhysicalDeviceTimelineSemaphoreProperties;
    typedef struct VkPhysicalDeviceTimelineSemaphorePropertiesKHR VkPhysicalDeviceTimelineSemaphorePropertiesKHR;
    typedef struct VkSemaphoreTypeCreateInfo VkSemaphoreTypeCreateInfo;
    typedef struct VkSemaphoreTypeCreateInfoKHR VkSemaphoreTypeCreateInfoKHR;
    typedef struct VkTimelineSemaphoreSubmitInfo VkTimelineSemaphoreSubmitInfo;
    typedef struct VkTimelineSemaphoreSubmitInfoKHR VkTimelineSemaphoreSubmitInfoKHR;
    typedef struct VkSemaphoreWaitInfo VkSemaphoreWaitInfo;
    typedef struct VkSemaphoreWaitInfoKHR VkSemaphoreWaitInfoKHR;
    typedef struct VkSemaphoreSignalInfo VkSemaphoreSignalInfo;
    typedef struct VkSemaphoreSignalInfoKHR VkSemaphoreSignalInfoKHR;
    typedef struct VkVertexInputBindingDivisorDescription VkVertexInputBindingDivisorDescription;
    typedef struct VkVertexInputBindingDivisorDescriptionKHR VkVertexInputBindingDivisorDescriptionKHR;
    typedef struct VkVertexInputBindingDivisorDescriptionEXT VkVertexInputBindingDivisorDescriptionEXT;
    typedef struct VkPipelineVertexInputDivisorStateCreateInfo VkPipelineVertexInputDivisorStateCreateInfo;
    typedef struct VkPipelineVertexInputDivisorStateCreateInfoKHR VkPipelineVertexInputDivisorStateCreateInfoKHR;
    typedef struct VkPipelineVertexInputDivisorStateCreateInfoEXT VkPipelineVertexInputDivisorStateCreateInfoEXT;
    typedef struct VkPhysicalDeviceVertexAttributeDivisorPropertiesEXT VkPhysicalDeviceVertexAttributeDivisorPropertiesEXT;
    typedef struct VkPhysicalDeviceVertexAttributeDivisorProperties VkPhysicalDeviceVertexAttributeDivisorProperties;
    typedef struct VkPhysicalDeviceVertexAttributeDivisorPropertiesKHR VkPhysicalDeviceVertexAttributeDivisorPropertiesKHR;
    typedef struct VkPhysicalDevicePCIBusInfoPropertiesEXT VkPhysicalDevicePCIBusInfoPropertiesEXT;
    typedef struct VkImportAndroidHardwareBufferInfoANDROID VkImportAndroidHardwareBufferInfoANDROID;
    typedef struct VkAndroidHardwareBufferUsageANDROID VkAndroidHardwareBufferUsageANDROID;
    typedef struct VkAndroidHardwareBufferPropertiesANDROID VkAndroidHardwareBufferPropertiesANDROID;
    typedef struct VkMemoryGetAndroidHardwareBufferInfoANDROID VkMemoryGetAndroidHardwareBufferInfoANDROID;
    typedef struct VkAndroidHardwareBufferFormatPropertiesANDROID VkAndroidHardwareBufferFormatPropertiesANDROID;
    typedef struct VkCommandBufferInheritanceConditionalRenderingInfoEXT VkCommandBufferInheritanceConditionalRenderingInfoEXT;
    typedef struct VkExternalFormatANDROID VkExternalFormatANDROID;
    typedef struct VkPhysicalDevice8BitStorageFeatures VkPhysicalDevice8BitStorageFeatures;
    typedef struct VkPhysicalDevice8BitStorageFeaturesKHR VkPhysicalDevice8BitStorageFeaturesKHR;
    typedef struct VkPhysicalDeviceConditionalRenderingFeaturesEXT VkPhysicalDeviceConditionalRenderingFeaturesEXT;
    typedef struct VkPhysicalDeviceVulkanMemoryModelFeatures VkPhysicalDeviceVulkanMemoryModelFeatures;
    typedef struct VkPhysicalDeviceVulkanMemoryModelFeaturesKHR VkPhysicalDeviceVulkanMemoryModelFeaturesKHR;
    typedef struct VkPhysicalDeviceShaderAtomicInt64Features VkPhysicalDeviceShaderAtomicInt64Features;
    typedef struct VkPhysicalDeviceShaderAtomicInt64FeaturesKHR VkPhysicalDeviceShaderAtomicInt64FeaturesKHR;
    typedef struct VkPhysicalDeviceShaderAtomicFloatFeaturesEXT VkPhysicalDeviceShaderAtomicFloatFeaturesEXT;
    typedef struct VkPhysicalDeviceShaderAtomicFloat2FeaturesEXT VkPhysicalDeviceShaderAtomicFloat2FeaturesEXT;
    typedef struct VkPhysicalDeviceVertexAttributeDivisorFeatures VkPhysicalDeviceVertexAttributeDivisorFeatures;
    typedef struct VkPhysicalDeviceVertexAttributeDivisorFeaturesKHR VkPhysicalDeviceVertexAttributeDivisorFeaturesKHR;
    typedef struct VkPhysicalDeviceVertexAttributeDivisorFeaturesEXT VkPhysicalDeviceVertexAttributeDivisorFeaturesEXT;
    typedef struct VkQueueFamilyCheckpointPropertiesNV VkQueueFamilyCheckpointPropertiesNV;
    typedef struct VkCheckpointDataNV VkCheckpointDataNV;
    typedef struct VkPhysicalDeviceDepthStencilResolveProperties VkPhysicalDeviceDepthStencilResolveProperties;
    typedef struct VkPhysicalDeviceDepthStencilResolvePropertiesKHR VkPhysicalDeviceDepthStencilResolvePropertiesKHR;
    typedef struct VkSubpassDescriptionDepthStencilResolve VkSubpassDescriptionDepthStencilResolve;
    typedef struct VkSubpassDescriptionDepthStencilResolveKHR VkSubpassDescriptionDepthStencilResolveKHR;
    typedef struct VkImageViewASTCDecodeModeEXT VkImageViewASTCDecodeModeEXT;
    typedef struct VkPhysicalDeviceASTCDecodeFeaturesEXT VkPhysicalDeviceASTCDecodeFeaturesEXT;
    typedef struct VkPhysicalDeviceTransformFeedbackFeaturesEXT VkPhysicalDeviceTransformFeedbackFeaturesEXT;
    typedef struct VkPhysicalDeviceTransformFeedbackPropertiesEXT VkPhysicalDeviceTransformFeedbackPropertiesEXT;
    typedef struct VkPipelineRasterizationStateStreamCreateInfoEXT VkPipelineRasterizationStateStreamCreateInfoEXT;
    typedef struct VkPhysicalDeviceRepresentativeFragmentTestFeaturesNV VkPhysicalDeviceRepresentativeFragmentTestFeaturesNV;
    typedef struct VkPipelineRepresentativeFragmentTestStateCreateInfoNV VkPipelineRepresentativeFragmentTestStateCreateInfoNV;
    typedef struct VkPhysicalDeviceExclusiveScissorFeaturesNV VkPhysicalDeviceExclusiveScissorFeaturesNV;
    typedef struct VkPipelineViewportExclusiveScissorStateCreateInfoNV VkPipelineViewportExclusiveScissorStateCreateInfoNV;
    typedef struct VkPhysicalDeviceCornerSampledImageFeaturesNV VkPhysicalDeviceCornerSampledImageFeaturesNV;
    typedef struct VkPhysicalDeviceComputeShaderDerivativesFeaturesKHR VkPhysicalDeviceComputeShaderDerivativesFeaturesKHR;
    typedef struct VkPhysicalDeviceComputeShaderDerivativesFeaturesNV VkPhysicalDeviceComputeShaderDerivativesFeaturesNV;
    typedef struct VkPhysicalDeviceComputeShaderDerivativesPropertiesKHR VkPhysicalDeviceComputeShaderDerivativesPropertiesKHR;
    typedef struct VkPhysicalDeviceFragmentShaderBarycentricFeaturesNV VkPhysicalDeviceFragmentShaderBarycentricFeaturesNV;
    typedef struct VkPhysicalDeviceShaderImageFootprintFeaturesNV VkPhysicalDeviceShaderImageFootprintFeaturesNV;
    typedef struct VkPhysicalDeviceDedicatedAllocationImageAliasingFeaturesNV VkPhysicalDeviceDedicatedAllocationImageAliasingFeaturesNV;
    typedef struct VkPhysicalDeviceCopyMemoryIndirectFeaturesKHR VkPhysicalDeviceCopyMemoryIndirectFeaturesKHR;
    typedef struct VkPhysicalDeviceCopyMemoryIndirectFeaturesNV VkPhysicalDeviceCopyMemoryIndirectFeaturesNV;
    typedef struct VkPhysicalDeviceCopyMemoryIndirectPropertiesKHR VkPhysicalDeviceCopyMemoryIndirectPropertiesKHR;
    typedef struct VkPhysicalDeviceCopyMemoryIndirectPropertiesNV VkPhysicalDeviceCopyMemoryIndirectPropertiesNV;
    typedef struct VkPhysicalDeviceMemoryDecompressionFeaturesEXT VkPhysicalDeviceMemoryDecompressionFeaturesEXT;
    typedef struct VkPhysicalDeviceMemoryDecompressionFeaturesNV VkPhysicalDeviceMemoryDecompressionFeaturesNV;
    typedef struct VkPhysicalDeviceMemoryDecompressionPropertiesEXT VkPhysicalDeviceMemoryDecompressionPropertiesEXT;
    typedef struct VkPhysicalDeviceMemoryDecompressionPropertiesNV VkPhysicalDeviceMemoryDecompressionPropertiesNV;
    typedef struct VkShadingRatePaletteNV VkShadingRatePaletteNV;
    typedef struct VkPipelineViewportShadingRateImageStateCreateInfoNV VkPipelineViewportShadingRateImageStateCreateInfoNV;
    typedef struct VkPhysicalDeviceShadingRateImageFeaturesNV VkPhysicalDeviceShadingRateImageFeaturesNV;
    typedef struct VkPhysicalDeviceShadingRateImagePropertiesNV VkPhysicalDeviceShadingRateImagePropertiesNV;
    typedef struct VkPhysicalDeviceInvocationMaskFeaturesHUAWEI VkPhysicalDeviceInvocationMaskFeaturesHUAWEI;
    typedef struct VkCoarseSampleLocationNV VkCoarseSampleLocationNV;
    typedef struct VkCoarseSampleOrderCustomNV VkCoarseSampleOrderCustomNV;
    typedef struct VkPipelineViewportCoarseSampleOrderStateCreateInfoNV VkPipelineViewportCoarseSampleOrderStateCreateInfoNV;
    typedef struct VkPhysicalDeviceMeshShaderFeaturesNV VkPhysicalDeviceMeshShaderFeaturesNV;
    typedef struct VkPhysicalDeviceMeshShaderPropertiesNV VkPhysicalDeviceMeshShaderPropertiesNV;
    typedef struct VkDrawMeshTasksIndirectCommandNV VkDrawMeshTasksIndirectCommandNV;
    typedef struct VkPhysicalDeviceMeshShaderFeaturesEXT VkPhysicalDeviceMeshShaderFeaturesEXT;
    typedef struct VkPhysicalDeviceMeshShaderPropertiesEXT VkPhysicalDeviceMeshShaderPropertiesEXT;
    typedef struct VkDrawMeshTasksIndirectCommandEXT VkDrawMeshTasksIndirectCommandEXT;
    typedef struct VkRayTracingShaderGroupCreateInfoNV VkRayTracingShaderGroupCreateInfoNV;
    typedef struct VkRayTracingShaderGroupCreateInfoKHR VkRayTracingShaderGroupCreateInfoKHR;
    typedef struct VkRayTracingPipelineCreateInfoNV VkRayTracingPipelineCreateInfoNV;
    typedef struct VkRayTracingPipelineCreateInfoKHR VkRayTracingPipelineCreateInfoKHR;
    typedef struct VkGeometryTrianglesNV VkGeometryTrianglesNV;
    typedef struct VkGeometryAABBNV VkGeometryAABBNV;
    typedef struct VkGeometryDataNV VkGeometryDataNV;
    typedef struct VkGeometryNV VkGeometryNV;
    typedef struct VkAccelerationStructureInfoNV VkAccelerationStructureInfoNV;
    typedef struct VkAccelerationStructureCreateInfoNV VkAccelerationStructureCreateInfoNV;
    typedef struct VkBindAccelerationStructureMemoryInfoNV VkBindAccelerationStructureMemoryInfoNV;
    typedef struct VkWriteDescriptorSetAccelerationStructureKHR VkWriteDescriptorSetAccelerationStructureKHR;
    typedef struct VkWriteDescriptorSetAccelerationStructureNV VkWriteDescriptorSetAccelerationStructureNV;
    typedef struct VkAccelerationStructureMemoryRequirementsInfoNV VkAccelerationStructureMemoryRequirementsInfoNV;
    typedef struct VkPhysicalDeviceAccelerationStructureFeaturesKHR VkPhysicalDeviceAccelerationStructureFeaturesKHR;
    typedef struct VkPhysicalDeviceRayTracingPipelineFeaturesKHR VkPhysicalDeviceRayTracingPipelineFeaturesKHR;
    typedef struct VkPhysicalDeviceRayQueryFeaturesKHR VkPhysicalDeviceRayQueryFeaturesKHR;
    typedef struct VkPhysicalDeviceAccelerationStructurePropertiesKHR VkPhysicalDeviceAccelerationStructurePropertiesKHR;
    typedef struct VkPhysicalDeviceRayTracingPipelinePropertiesKHR VkPhysicalDeviceRayTracingPipelinePropertiesKHR;
    typedef struct VkPhysicalDeviceRayTracingPropertiesNV VkPhysicalDeviceRayTracingPropertiesNV;
    typedef struct VkStridedDeviceAddressRegionKHR VkStridedDeviceAddressRegionKHR;
    typedef struct VkTraceRaysIndirectCommandKHR VkTraceRaysIndirectCommandKHR;
    typedef struct VkTraceRaysIndirectCommand2KHR VkTraceRaysIndirectCommand2KHR;
    typedef struct VkPhysicalDeviceRayTracingMaintenance1FeaturesKHR VkPhysicalDeviceRayTracingMaintenance1FeaturesKHR;
    typedef struct VkDrmFormatModifierPropertiesListEXT VkDrmFormatModifierPropertiesListEXT;
    typedef struct VkDrmFormatModifierPropertiesEXT VkDrmFormatModifierPropertiesEXT;
    typedef struct VkPhysicalDeviceImageDrmFormatModifierInfoEXT VkPhysicalDeviceImageDrmFormatModifierInfoEXT;
    typedef struct VkImageDrmFormatModifierListCreateInfoEXT VkImageDrmFormatModifierListCreateInfoEXT;
    typedef struct VkImageDrmFormatModifierExplicitCreateInfoEXT VkImageDrmFormatModifierExplicitCreateInfoEXT;
    typedef struct VkImageDrmFormatModifierPropertiesEXT VkImageDrmFormatModifierPropertiesEXT;
    typedef struct VkImageStencilUsageCreateInfo VkImageStencilUsageCreateInfo;
    typedef struct VkImageStencilUsageCreateInfoEXT VkImageStencilUsageCreateInfoEXT;
    typedef struct VkDeviceMemoryOverallocationCreateInfoAMD VkDeviceMemoryOverallocationCreateInfoAMD;
    typedef struct VkPhysicalDeviceFragmentDensityMapFeaturesEXT VkPhysicalDeviceFragmentDensityMapFeaturesEXT;
    typedef struct VkPhysicalDeviceFragmentDensityMap2FeaturesEXT VkPhysicalDeviceFragmentDensityMap2FeaturesEXT;
    typedef struct VkPhysicalDeviceFragmentDensityMapOffsetFeaturesEXT VkPhysicalDeviceFragmentDensityMapOffsetFeaturesEXT;
    typedef struct VkPhysicalDeviceFragmentDensityMapOffsetFeaturesQCOM VkPhysicalDeviceFragmentDensityMapOffsetFeaturesQCOM;
    typedef struct VkPhysicalDeviceFragmentDensityMapPropertiesEXT VkPhysicalDeviceFragmentDensityMapPropertiesEXT;
    typedef struct VkPhysicalDeviceFragmentDensityMap2PropertiesEXT VkPhysicalDeviceFragmentDensityMap2PropertiesEXT;
    typedef struct VkPhysicalDeviceFragmentDensityMapOffsetPropertiesEXT VkPhysicalDeviceFragmentDensityMapOffsetPropertiesEXT;
    typedef struct VkPhysicalDeviceFragmentDensityMapOffsetPropertiesQCOM VkPhysicalDeviceFragmentDensityMapOffsetPropertiesQCOM;
    typedef struct VkRenderPassFragmentDensityMapCreateInfoEXT VkRenderPassFragmentDensityMapCreateInfoEXT;
    typedef struct VkRenderPassFragmentDensityMapOffsetEndInfoEXT VkRenderPassFragmentDensityMapOffsetEndInfoEXT;
    typedef struct VkSubpassFragmentDensityMapOffsetEndInfoQCOM VkSubpassFragmentDensityMapOffsetEndInfoQCOM;
    typedef struct VkPhysicalDeviceScalarBlockLayoutFeatures VkPhysicalDeviceScalarBlockLayoutFeatures;
    typedef struct VkPhysicalDeviceScalarBlockLayoutFeaturesEXT VkPhysicalDeviceScalarBlockLayoutFeaturesEXT;
    typedef struct VkSurfaceProtectedCapabilitiesKHR VkSurfaceProtectedCapabilitiesKHR;
    typedef struct VkPhysicalDeviceUniformBufferStandardLayoutFeatures VkPhysicalDeviceUniformBufferStandardLayoutFeatures;
    typedef struct VkPhysicalDeviceUniformBufferStandardLayoutFeaturesKHR VkPhysicalDeviceUniformBufferStandardLayoutFeaturesKHR;
    typedef struct VkPhysicalDeviceDepthClipEnableFeaturesEXT VkPhysicalDeviceDepthClipEnableFeaturesEXT;
    typedef struct VkPipelineRasterizationDepthClipStateCreateInfoEXT VkPipelineRasterizationDepthClipStateCreateInfoEXT;
    typedef struct VkPhysicalDeviceMemoryBudgetPropertiesEXT VkPhysicalDeviceMemoryBudgetPropertiesEXT;
    typedef struct VkPhysicalDeviceMemoryPriorityFeaturesEXT VkPhysicalDeviceMemoryPriorityFeaturesEXT;
    typedef struct VkMemoryPriorityAllocateInfoEXT VkMemoryPriorityAllocateInfoEXT;
    typedef struct VkPhysicalDevicePageableDeviceLocalMemoryFeaturesEXT VkPhysicalDevicePageableDeviceLocalMemoryFeaturesEXT;
    typedef struct VkPhysicalDeviceBufferDeviceAddressFeatures VkPhysicalDeviceBufferDeviceAddressFeatures;
    typedef struct VkPhysicalDeviceBufferDeviceAddressFeaturesKHR VkPhysicalDeviceBufferDeviceAddressFeaturesKHR;
    typedef struct VkPhysicalDeviceBufferDeviceAddressFeaturesEXT VkPhysicalDeviceBufferDeviceAddressFeaturesEXT;
    typedef struct VkPhysicalDeviceBufferAddressFeaturesEXT VkPhysicalDeviceBufferAddressFeaturesEXT;
    typedef struct VkBufferDeviceAddressInfo VkBufferDeviceAddressInfo;
    typedef struct VkBufferDeviceAddressInfoKHR VkBufferDeviceAddressInfoKHR;
    typedef struct VkBufferDeviceAddressInfoEXT VkBufferDeviceAddressInfoEXT;
    typedef struct VkBufferOpaqueCaptureAddressCreateInfo VkBufferOpaqueCaptureAddressCreateInfo;
    typedef struct VkBufferOpaqueCaptureAddressCreateInfoKHR VkBufferOpaqueCaptureAddressCreateInfoKHR;
    typedef struct VkBufferDeviceAddressCreateInfoEXT VkBufferDeviceAddressCreateInfoEXT;
    typedef struct VkPhysicalDeviceImageViewImageFormatInfoEXT VkPhysicalDeviceImageViewImageFormatInfoEXT;
    typedef struct VkFilterCubicImageViewImageFormatPropertiesEXT VkFilterCubicImageViewImageFormatPropertiesEXT;
    typedef struct VkPhysicalDeviceImagelessFramebufferFeatures VkPhysicalDeviceImagelessFramebufferFeatures;
    typedef struct VkPhysicalDeviceImagelessFramebufferFeaturesKHR VkPhysicalDeviceImagelessFramebufferFeaturesKHR;
    typedef struct VkFramebufferAttachmentsCreateInfo VkFramebufferAttachmentsCreateInfo;
    typedef struct VkFramebufferAttachmentsCreateInfoKHR VkFramebufferAttachmentsCreateInfoKHR;
    typedef struct VkFramebufferAttachmentImageInfo VkFramebufferAttachmentImageInfo;
    typedef struct VkFramebufferAttachmentImageInfoKHR VkFramebufferAttachmentImageInfoKHR;
    typedef struct VkRenderPassAttachmentBeginInfo VkRenderPassAttachmentBeginInfo;
    typedef struct VkRenderPassAttachmentBeginInfoKHR VkRenderPassAttachmentBeginInfoKHR;
    typedef struct VkPhysicalDeviceTextureCompressionASTCHDRFeatures VkPhysicalDeviceTextureCompressionASTCHDRFeatures;
    typedef struct VkPhysicalDeviceTextureCompressionASTCHDRFeaturesEXT VkPhysicalDeviceTextureCompressionASTCHDRFeaturesEXT;
    typedef struct VkPhysicalDeviceCooperativeMatrixFeaturesNV VkPhysicalDeviceCooperativeMatrixFeaturesNV;
    typedef struct VkPhysicalDeviceCooperativeMatrixPropertiesNV VkPhysicalDeviceCooperativeMatrixPropertiesNV;
    typedef struct VkCooperativeMatrixPropertiesNV VkCooperativeMatrixPropertiesNV;
    typedef struct VkPhysicalDeviceYcbcrImageArraysFeaturesEXT VkPhysicalDeviceYcbcrImageArraysFeaturesEXT;
    typedef struct VkImageViewHandleInfoNVX VkImageViewHandleInfoNVX;
    typedef struct VkImageViewAddressPropertiesNVX VkImageViewAddressPropertiesNVX;
    typedef struct VkPresentFrameTokenGGP VkPresentFrameTokenGGP;
    typedef struct VkPipelineCreationFeedback VkPipelineCreationFeedback;
    typedef struct VkPipelineCreationFeedbackEXT VkPipelineCreationFeedbackEXT;
    typedef struct VkPipelineCreationFeedbackCreateInfo VkPipelineCreationFeedbackCreateInfo;
    typedef struct VkPipelineCreationFeedbackCreateInfoEXT VkPipelineCreationFeedbackCreateInfoEXT;
    typedef struct VkSurfaceFullScreenExclusiveInfoEXT VkSurfaceFullScreenExclusiveInfoEXT;
    typedef struct VkSurfaceFullScreenExclusiveWin32InfoEXT VkSurfaceFullScreenExclusiveWin32InfoEXT;
    typedef struct VkSurfaceCapabilitiesFullScreenExclusiveEXT VkSurfaceCapabilitiesFullScreenExclusiveEXT;
    typedef struct VkPhysicalDevicePresentBarrierFeaturesNV VkPhysicalDevicePresentBarrierFeaturesNV;
    typedef struct VkSurfaceCapabilitiesPresentBarrierNV VkSurfaceCapabilitiesPresentBarrierNV;
    typedef struct VkSwapchainPresentBarrierCreateInfoNV VkSwapchainPresentBarrierCreateInfoNV;
    typedef struct VkPhysicalDevicePerformanceQueryFeaturesKHR VkPhysicalDevicePerformanceQueryFeaturesKHR;
    typedef struct VkPhysicalDevicePerformanceQueryPropertiesKHR VkPhysicalDevicePerformanceQueryPropertiesKHR;
    typedef struct VkPerformanceCounterKHR VkPerformanceCounterKHR;
    typedef struct VkPerformanceCounterDescriptionKHR VkPerformanceCounterDescriptionKHR;
    typedef struct VkQueryPoolPerformanceCreateInfoKHR VkQueryPoolPerformanceCreateInfoKHR;
    typedef union VkPerformanceCounterResultKHR VkPerformanceCounterResultKHR;
    typedef struct VkAcquireProfilingLockInfoKHR VkAcquireProfilingLockInfoKHR;
    typedef struct VkPerformanceQuerySubmitInfoKHR VkPerformanceQuerySubmitInfoKHR;
    typedef struct VkPerformanceQueryReservationInfoKHR VkPerformanceQueryReservationInfoKHR;
    typedef struct VkHeadlessSurfaceCreateInfoEXT VkHeadlessSurfaceCreateInfoEXT;
    typedef struct VkPhysicalDeviceCoverageReductionModeFeaturesNV VkPhysicalDeviceCoverageReductionModeFeaturesNV;
    typedef struct VkPipelineCoverageReductionStateCreateInfoNV VkPipelineCoverageReductionStateCreateInfoNV;
    typedef struct VkFramebufferMixedSamplesCombinationNV VkFramebufferMixedSamplesCombinationNV;
    typedef struct VkPhysicalDeviceShaderIntegerFunctions2FeaturesINTEL VkPhysicalDeviceShaderIntegerFunctions2FeaturesINTEL;
    typedef union VkPerformanceValueDataINTEL VkPerformanceValueDataINTEL;
    typedef struct VkPerformanceValueINTEL VkPerformanceValueINTEL;
    typedef struct VkInitializePerformanceApiInfoINTEL VkInitializePerformanceApiInfoINTEL;
    typedef struct VkQueryPoolPerformanceQueryCreateInfoINTEL VkQueryPoolPerformanceQueryCreateInfoINTEL;
    typedef struct VkQueryPoolCreateInfoINTEL VkQueryPoolCreateInfoINTEL;
    typedef struct VkPerformanceMarkerInfoINTEL VkPerformanceMarkerInfoINTEL;
    typedef struct VkPerformanceStreamMarkerInfoINTEL VkPerformanceStreamMarkerInfoINTEL;
    typedef struct VkPerformanceOverrideInfoINTEL VkPerformanceOverrideInfoINTEL;
    typedef struct VkPerformanceConfigurationAcquireInfoINTEL VkPerformanceConfigurationAcquireInfoINTEL;
    typedef struct VkPhysicalDeviceShaderClockFeaturesKHR VkPhysicalDeviceShaderClockFeaturesKHR;
    typedef struct VkPhysicalDeviceIndexTypeUint8Features VkPhysicalDeviceIndexTypeUint8Features;
    typedef struct VkPhysicalDeviceIndexTypeUint8FeaturesKHR VkPhysicalDeviceIndexTypeUint8FeaturesKHR;
    typedef struct VkPhysicalDeviceIndexTypeUint8FeaturesEXT VkPhysicalDeviceIndexTypeUint8FeaturesEXT;
    typedef struct VkPhysicalDeviceShaderSMBuiltinsPropertiesNV VkPhysicalDeviceShaderSMBuiltinsPropertiesNV;
    typedef struct VkPhysicalDeviceShaderSMBuiltinsFeaturesNV VkPhysicalDeviceShaderSMBuiltinsFeaturesNV;
    typedef struct VkPhysicalDeviceFragmentShaderInterlockFeaturesEXT VkPhysicalDeviceFragmentShaderInterlockFeaturesEXT;
    typedef struct VkPhysicalDeviceSeparateDepthStencilLayoutsFeatures VkPhysicalDeviceSeparateDepthStencilLayoutsFeatures;
    typedef struct VkPhysicalDeviceSeparateDepthStencilLayoutsFeaturesKHR VkPhysicalDeviceSeparateDepthStencilLayoutsFeaturesKHR;
    typedef struct VkAttachmentReferenceStencilLayout VkAttachmentReferenceStencilLayout;
    typedef struct VkPhysicalDevicePrimitiveTopologyListRestartFeaturesEXT VkPhysicalDevicePrimitiveTopologyListRestartFeaturesEXT;
    typedef struct VkAttachmentReferenceStencilLayoutKHR VkAttachmentReferenceStencilLayoutKHR;
    typedef struct VkAttachmentDescriptionStencilLayout VkAttachmentDescriptionStencilLayout;
    typedef struct VkAttachmentDescriptionStencilLayoutKHR VkAttachmentDescriptionStencilLayoutKHR;
    typedef struct VkPhysicalDevicePipelineExecutablePropertiesFeaturesKHR VkPhysicalDevicePipelineExecutablePropertiesFeaturesKHR;
    typedef struct VkPipelineInfoKHR VkPipelineInfoKHR;
    typedef struct VkPipelineInfoEXT VkPipelineInfoEXT;
    typedef struct VkPipelineExecutablePropertiesKHR VkPipelineExecutablePropertiesKHR;
    typedef struct VkPipelineExecutableInfoKHR VkPipelineExecutableInfoKHR;
    typedef union VkPipelineExecutableStatisticValueKHR VkPipelineExecutableStatisticValueKHR;
    typedef struct VkPipelineExecutableStatisticKHR VkPipelineExecutableStatisticKHR;
    typedef struct VkPipelineExecutableInternalRepresentationKHR VkPipelineExecutableInternalRepresentationKHR;
    typedef struct VkPhysicalDeviceShaderDemoteToHelperInvocationFeatures VkPhysicalDeviceShaderDemoteToHelperInvocationFeatures;
    typedef struct VkPhysicalDeviceShaderDemoteToHelperInvocationFeaturesEXT VkPhysicalDeviceShaderDemoteToHelperInvocationFeaturesEXT;
    typedef struct VkPhysicalDeviceTexelBufferAlignmentFeaturesEXT VkPhysicalDeviceTexelBufferAlignmentFeaturesEXT;
    typedef struct VkPhysicalDeviceTexelBufferAlignmentProperties VkPhysicalDeviceTexelBufferAlignmentProperties;
    typedef struct VkPhysicalDeviceTexelBufferAlignmentPropertiesEXT VkPhysicalDeviceTexelBufferAlignmentPropertiesEXT;
    typedef struct VkPhysicalDeviceSubgroupSizeControlFeatures VkPhysicalDeviceSubgroupSizeControlFeatures;
    typedef struct VkPhysicalDeviceSubgroupSizeControlFeaturesEXT VkPhysicalDeviceSubgroupSizeControlFeaturesEXT;
    typedef struct VkPhysicalDeviceSubgroupSizeControlProperties VkPhysicalDeviceSubgroupSizeControlProperties;
    typedef struct VkPhysicalDeviceSubgroupSizeControlPropertiesEXT VkPhysicalDeviceSubgroupSizeControlPropertiesEXT;
    typedef struct VkPipelineShaderStageRequiredSubgroupSizeCreateInfo VkPipelineShaderStageRequiredSubgroupSizeCreateInfo;
    typedef struct VkPipelineShaderStageRequiredSubgroupSizeCreateInfoEXT VkPipelineShaderStageRequiredSubgroupSizeCreateInfoEXT;
    typedef struct VkShaderRequiredSubgroupSizeCreateInfoEXT VkShaderRequiredSubgroupSizeCreateInfoEXT;
    typedef struct VkSubpassShadingPipelineCreateInfoHUAWEI VkSubpassShadingPipelineCreateInfoHUAWEI;
    typedef struct VkPhysicalDeviceSubpassShadingPropertiesHUAWEI VkPhysicalDeviceSubpassShadingPropertiesHUAWEI;
    typedef struct VkPhysicalDeviceClusterCullingShaderPropertiesHUAWEI VkPhysicalDeviceClusterCullingShaderPropertiesHUAWEI;
    typedef struct VkMemoryOpaqueCaptureAddressAllocateInfo VkMemoryOpaqueCaptureAddressAllocateInfo;
    typedef struct VkMemoryOpaqueCaptureAddressAllocateInfoKHR VkMemoryOpaqueCaptureAddressAllocateInfoKHR;
    typedef struct VkDeviceMemoryOpaqueCaptureAddressInfo VkDeviceMemoryOpaqueCaptureAddressInfo;
    typedef struct VkDeviceMemoryOpaqueCaptureAddressInfoKHR VkDeviceMemoryOpaqueCaptureAddressInfoKHR;
    typedef struct VkPhysicalDeviceLineRasterizationFeatures VkPhysicalDeviceLineRasterizationFeatures;
    typedef struct VkPhysicalDeviceLineRasterizationFeaturesKHR VkPhysicalDeviceLineRasterizationFeaturesKHR;
    typedef struct VkPhysicalDeviceLineRasterizationFeaturesEXT VkPhysicalDeviceLineRasterizationFeaturesEXT;
    typedef struct VkPhysicalDeviceLineRasterizationProperties VkPhysicalDeviceLineRasterizationProperties;
    typedef struct VkPhysicalDeviceLineRasterizationPropertiesKHR VkPhysicalDeviceLineRasterizationPropertiesKHR;
    typedef struct VkPhysicalDeviceLineRasterizationPropertiesEXT VkPhysicalDeviceLineRasterizationPropertiesEXT;
    typedef struct VkPipelineRasterizationLineStateCreateInfo VkPipelineRasterizationLineStateCreateInfo;
    typedef struct VkPipelineRasterizationLineStateCreateInfoKHR VkPipelineRasterizationLineStateCreateInfoKHR;
    typedef struct VkPipelineRasterizationLineStateCreateInfoEXT VkPipelineRasterizationLineStateCreateInfoEXT;
    typedef struct VkPhysicalDevicePipelineCreationCacheControlFeatures VkPhysicalDevicePipelineCreationCacheControlFeatures;
    typedef struct VkPhysicalDevicePipelineCreationCacheControlFeaturesEXT VkPhysicalDevicePipelineCreationCacheControlFeaturesEXT;
    typedef struct VkPhysicalDeviceVulkan11Features VkPhysicalDeviceVulkan11Features;
    typedef struct VkPhysicalDeviceVulkan11Properties VkPhysicalDeviceVulkan11Properties;
    typedef struct VkPhysicalDeviceVulkan12Features VkPhysicalDeviceVulkan12Features;
    typedef struct VkPhysicalDeviceVulkan12Properties VkPhysicalDeviceVulkan12Properties;
    typedef struct VkPhysicalDeviceVulkan13Features VkPhysicalDeviceVulkan13Features;
    typedef struct VkPhysicalDeviceVulkan13Properties VkPhysicalDeviceVulkan13Properties;
    typedef struct VkPhysicalDeviceVulkan14Features VkPhysicalDeviceVulkan14Features;
    typedef struct VkPhysicalDeviceVulkan14Properties VkPhysicalDeviceVulkan14Properties;
    typedef struct VkPipelineCompilerControlCreateInfoAMD VkPipelineCompilerControlCreateInfoAMD;
    typedef struct VkPhysicalDeviceCoherentMemoryFeaturesAMD VkPhysicalDeviceCoherentMemoryFeaturesAMD;
    typedef struct VkFaultData VkFaultData;
    typedef struct VkFaultCallbackInfo VkFaultCallbackInfo;
    typedef struct VkPhysicalDeviceToolProperties VkPhysicalDeviceToolProperties;
    typedef struct VkPhysicalDeviceToolPropertiesEXT VkPhysicalDeviceToolPropertiesEXT;
    typedef struct VkSamplerCustomBorderColorCreateInfoEXT VkSamplerCustomBorderColorCreateInfoEXT;
    typedef struct VkPhysicalDeviceCustomBorderColorPropertiesEXT VkPhysicalDeviceCustomBorderColorPropertiesEXT;
    typedef struct VkPhysicalDeviceCustomBorderColorFeaturesEXT VkPhysicalDeviceCustomBorderColorFeaturesEXT;
    typedef struct VkSamplerBorderColorComponentMappingCreateInfoEXT VkSamplerBorderColorComponentMappingCreateInfoEXT;
    typedef struct VkPhysicalDeviceBorderColorSwizzleFeaturesEXT VkPhysicalDeviceBorderColorSwizzleFeaturesEXT;
    typedef union VkDeviceOrHostAddressKHR VkDeviceOrHostAddressKHR;
    typedef union VkDeviceOrHostAddressConstKHR VkDeviceOrHostAddressConstKHR;
    typedef union VkDeviceOrHostAddressConstAMDX VkDeviceOrHostAddressConstAMDX;
    typedef struct VkAccelerationStructureGeometryTrianglesDataKHR VkAccelerationStructureGeometryTrianglesDataKHR;
    typedef struct VkAccelerationStructureGeometryAabbsDataKHR VkAccelerationStructureGeometryAabbsDataKHR;
    typedef struct VkAccelerationStructureGeometryInstancesDataKHR VkAccelerationStructureGeometryInstancesDataKHR;
    typedef struct VkAccelerationStructureGeometryLinearSweptSpheresDataNV VkAccelerationStructureGeometryLinearSweptSpheresDataNV;
    typedef struct VkAccelerationStructureGeometrySpheresDataNV VkAccelerationStructureGeometrySpheresDataNV;
    typedef union VkAccelerationStructureGeometryDataKHR VkAccelerationStructureGeometryDataKHR;
    typedef struct VkAccelerationStructureGeometryKHR VkAccelerationStructureGeometryKHR;
    typedef struct VkAccelerationStructureBuildGeometryInfoKHR VkAccelerationStructureBuildGeometryInfoKHR;
    typedef struct VkAccelerationStructureBuildRangeInfoKHR VkAccelerationStructureBuildRangeInfoKHR;
    typedef struct VkAccelerationStructureCreateInfoKHR VkAccelerationStructureCreateInfoKHR;
    typedef struct VkAabbPositionsKHR VkAabbPositionsKHR;
    typedef struct VkAabbPositionsNV VkAabbPositionsNV;
    typedef struct VkTransformMatrixKHR VkTransformMatrixKHR;
    typedef struct VkTransformMatrixNV VkTransformMatrixNV;
    typedef struct VkAccelerationStructureInstanceKHR VkAccelerationStructureInstanceKHR;
    typedef struct VkAccelerationStructureInstanceNV VkAccelerationStructureInstanceNV;
    typedef struct VkAccelerationStructureDeviceAddressInfoKHR VkAccelerationStructureDeviceAddressInfoKHR;
    typedef struct VkAccelerationStructureVersionInfoKHR VkAccelerationStructureVersionInfoKHR;
    typedef struct VkCopyAccelerationStructureInfoKHR VkCopyAccelerationStructureInfoKHR;
    typedef struct VkCopyAccelerationStructureToMemoryInfoKHR VkCopyAccelerationStructureToMemoryInfoKHR;
    typedef struct VkCopyMemoryToAccelerationStructureInfoKHR VkCopyMemoryToAccelerationStructureInfoKHR;
    typedef struct VkRayTracingPipelineInterfaceCreateInfoKHR VkRayTracingPipelineInterfaceCreateInfoKHR;
    typedef struct VkPipelineLibraryCreateInfoKHR VkPipelineLibraryCreateInfoKHR;
    typedef struct VkRefreshObjectKHR VkRefreshObjectKHR;
    typedef struct VkRefreshObjectListKHR VkRefreshObjectListKHR;
    typedef struct VkPhysicalDeviceExtendedDynamicStateFeaturesEXT VkPhysicalDeviceExtendedDynamicStateFeaturesEXT;
    typedef struct VkPhysicalDeviceExtendedDynamicState2FeaturesEXT VkPhysicalDeviceExtendedDynamicState2FeaturesEXT;
    typedef struct VkPhysicalDeviceExtendedDynamicState3FeaturesEXT VkPhysicalDeviceExtendedDynamicState3FeaturesEXT;
    typedef struct VkPhysicalDeviceExtendedDynamicState3PropertiesEXT VkPhysicalDeviceExtendedDynamicState3PropertiesEXT;
    typedef struct VkColorBlendEquationEXT VkColorBlendEquationEXT;
    typedef struct VkColorBlendAdvancedEXT VkColorBlendAdvancedEXT;
    typedef struct VkRenderPassTransformBeginInfoQCOM VkRenderPassTransformBeginInfoQCOM;
    typedef struct VkCopyCommandTransformInfoQCOM VkCopyCommandTransformInfoQCOM;
    typedef struct VkCommandBufferInheritanceRenderPassTransformInfoQCOM VkCommandBufferInheritanceRenderPassTransformInfoQCOM;
    typedef struct VkPhysicalDevicePartitionedAccelerationStructureFeaturesNV VkPhysicalDevicePartitionedAccelerationStructureFeaturesNV;
    typedef struct VkPhysicalDevicePartitionedAccelerationStructurePropertiesNV VkPhysicalDevicePartitionedAccelerationStructurePropertiesNV;
    typedef struct VkBuildPartitionedAccelerationStructureIndirectCommandNV VkBuildPartitionedAccelerationStructureIndirectCommandNV;
    typedef struct VkPartitionedAccelerationStructureFlagsNV VkPartitionedAccelerationStructureFlagsNV;
    typedef struct VkPartitionedAccelerationStructureWriteInstanceDataNV VkPartitionedAccelerationStructureWriteInstanceDataNV;
    typedef struct VkPartitionedAccelerationStructureUpdateInstanceDataNV VkPartitionedAccelerationStructureUpdateInstanceDataNV;
    typedef struct VkPartitionedAccelerationStructureWritePartitionTranslationDataNV VkPartitionedAccelerationStructureWritePartitionTranslationDataNV;
    typedef struct VkWriteDescriptorSetPartitionedAccelerationStructureNV VkWriteDescriptorSetPartitionedAccelerationStructureNV;
    typedef struct VkPartitionedAccelerationStructureInstancesInputNV VkPartitionedAccelerationStructureInstancesInputNV;
    typedef struct VkBuildPartitionedAccelerationStructureInfoNV VkBuildPartitionedAccelerationStructureInfoNV;
    typedef struct VkPhysicalDeviceDiagnosticsConfigFeaturesNV VkPhysicalDeviceDiagnosticsConfigFeaturesNV;
    typedef struct VkDeviceDiagnosticsConfigCreateInfoNV VkDeviceDiagnosticsConfigCreateInfoNV;
    typedef struct VkPipelineOfflineCreateInfo VkPipelineOfflineCreateInfo;
    typedef struct VkPhysicalDeviceZeroInitializeWorkgroupMemoryFeatures VkPhysicalDeviceZeroInitializeWorkgroupMemoryFeatures;
    typedef struct VkPhysicalDeviceZeroInitializeWorkgroupMemoryFeaturesKHR VkPhysicalDeviceZeroInitializeWorkgroupMemoryFeaturesKHR;
    typedef struct VkPhysicalDeviceShaderSubgroupUniformControlFlowFeaturesKHR VkPhysicalDeviceShaderSubgroupUniformControlFlowFeaturesKHR;
    typedef struct VkPhysicalDeviceRobustness2FeaturesKHR VkPhysicalDeviceRobustness2FeaturesKHR;
    typedef struct VkPhysicalDeviceRobustness2FeaturesEXT VkPhysicalDeviceRobustness2FeaturesEXT;
    typedef struct VkPhysicalDeviceRobustness2PropertiesKHR VkPhysicalDeviceRobustness2PropertiesKHR;
    typedef struct VkPhysicalDeviceRobustness2PropertiesEXT VkPhysicalDeviceRobustness2PropertiesEXT;
    typedef struct VkPhysicalDeviceImageRobustnessFeatures VkPhysicalDeviceImageRobustnessFeatures;
    typedef struct VkPhysicalDeviceImageRobustnessFeaturesEXT VkPhysicalDeviceImageRobustnessFeaturesEXT;
    typedef struct VkPhysicalDeviceWorkgroupMemoryExplicitLayoutFeaturesKHR VkPhysicalDeviceWorkgroupMemoryExplicitLayoutFeaturesKHR;
    typedef struct VkPhysicalDevicePortabilitySubsetFeaturesKHR VkPhysicalDevicePortabilitySubsetFeaturesKHR;
    typedef struct VkPhysicalDevicePortabilitySubsetPropertiesKHR VkPhysicalDevicePortabilitySubsetPropertiesKHR;
    typedef struct VkPhysicalDevice4444FormatsFeaturesEXT VkPhysicalDevice4444FormatsFeaturesEXT;
    typedef struct VkPhysicalDeviceSubpassShadingFeaturesHUAWEI VkPhysicalDeviceSubpassShadingFeaturesHUAWEI;
    typedef struct VkPhysicalDeviceClusterCullingShaderFeaturesHUAWEI VkPhysicalDeviceClusterCullingShaderFeaturesHUAWEI;
    typedef struct VkPhysicalDeviceClusterCullingShaderVrsFeaturesHUAWEI VkPhysicalDeviceClusterCullingShaderVrsFeaturesHUAWEI;
    typedef struct VkBufferCopy2 VkBufferCopy2;
    typedef struct VkBufferCopy2KHR VkBufferCopy2KHR;
    typedef struct VkImageCopy2 VkImageCopy2;
    typedef struct VkImageCopy2KHR VkImageCopy2KHR;
    typedef struct VkImageBlit2 VkImageBlit2;
    typedef struct VkImageBlit2KHR VkImageBlit2KHR;
    typedef struct VkBufferImageCopy2 VkBufferImageCopy2;
    typedef struct VkBufferImageCopy2KHR VkBufferImageCopy2KHR;
    typedef struct VkImageResolve2 VkImageResolve2;
    typedef struct VkImageResolve2KHR VkImageResolve2KHR;
    typedef struct VkCopyBufferInfo2 VkCopyBufferInfo2;
    typedef struct VkCopyBufferInfo2KHR VkCopyBufferInfo2KHR;
    typedef struct VkCopyImageInfo2 VkCopyImageInfo2;
    typedef struct VkCopyImageInfo2KHR VkCopyImageInfo2KHR;
    typedef struct VkBlitImageInfo2 VkBlitImageInfo2;
    typedef struct VkBlitImageInfo2KHR VkBlitImageInfo2KHR;
    typedef struct VkCopyBufferToImageInfo2 VkCopyBufferToImageInfo2;
    typedef struct VkCopyBufferToImageInfo2KHR VkCopyBufferToImageInfo2KHR;
    typedef struct VkCopyImageToBufferInfo2 VkCopyImageToBufferInfo2;
    typedef struct VkCopyImageToBufferInfo2KHR VkCopyImageToBufferInfo2KHR;
    typedef struct VkResolveImageInfo2 VkResolveImageInfo2;
    typedef struct VkResolveImageInfo2KHR VkResolveImageInfo2KHR;
    typedef struct VkPhysicalDeviceShaderImageAtomicInt64FeaturesEXT VkPhysicalDeviceShaderImageAtomicInt64FeaturesEXT;
    typedef struct VkFragmentShadingRateAttachmentInfoKHR VkFragmentShadingRateAttachmentInfoKHR;
    typedef struct VkPipelineFragmentShadingRateStateCreateInfoKHR VkPipelineFragmentShadingRateStateCreateInfoKHR;
    typedef struct VkPhysicalDeviceFragmentShadingRateFeaturesKHR VkPhysicalDeviceFragmentShadingRateFeaturesKHR;
    typedef struct VkPhysicalDeviceFragmentShadingRatePropertiesKHR VkPhysicalDeviceFragmentShadingRatePropertiesKHR;
    typedef struct VkPhysicalDeviceFragmentShadingRateKHR VkPhysicalDeviceFragmentShadingRateKHR;
    typedef struct VkPhysicalDeviceShaderTerminateInvocationFeatures VkPhysicalDeviceShaderTerminateInvocationFeatures;
    typedef struct VkPhysicalDeviceShaderTerminateInvocationFeaturesKHR VkPhysicalDeviceShaderTerminateInvocationFeaturesKHR;
    typedef struct VkPhysicalDeviceFragmentShadingRateEnumsFeaturesNV VkPhysicalDeviceFragmentShadingRateEnumsFeaturesNV;
    typedef struct VkPhysicalDeviceFragmentShadingRateEnumsPropertiesNV VkPhysicalDeviceFragmentShadingRateEnumsPropertiesNV;
    typedef struct VkPipelineFragmentShadingRateEnumStateCreateInfoNV VkPipelineFragmentShadingRateEnumStateCreateInfoNV;
    typedef struct VkAccelerationStructureBuildSizesInfoKHR VkAccelerationStructureBuildSizesInfoKHR;
    typedef struct VkPhysicalDeviceImage2DViewOf3DFeaturesEXT VkPhysicalDeviceImage2DViewOf3DFeaturesEXT;
    typedef struct VkPhysicalDeviceImageSlicedViewOf3DFeaturesEXT VkPhysicalDeviceImageSlicedViewOf3DFeaturesEXT;
    typedef struct VkPhysicalDeviceAttachmentFeedbackLoopDynamicStateFeaturesEXT VkPhysicalDeviceAttachmentFeedbackLoopDynamicStateFeaturesEXT;
    typedef struct VkPhysicalDeviceLegacyVertexAttributesFeaturesEXT VkPhysicalDeviceLegacyVertexAttributesFeaturesEXT;
    typedef struct VkPhysicalDeviceLegacyVertexAttributesPropertiesEXT VkPhysicalDeviceLegacyVertexAttributesPropertiesEXT;
    typedef struct VkPhysicalDeviceMutableDescriptorTypeFeaturesEXT VkPhysicalDeviceMutableDescriptorTypeFeaturesEXT;
    typedef struct VkPhysicalDeviceMutableDescriptorTypeFeaturesVALVE VkPhysicalDeviceMutableDescriptorTypeFeaturesVALVE;
    typedef struct VkMutableDescriptorTypeListEXT VkMutableDescriptorTypeListEXT;
    typedef struct VkMutableDescriptorTypeListVALVE VkMutableDescriptorTypeListVALVE;
    typedef struct VkMutableDescriptorTypeCreateInfoEXT VkMutableDescriptorTypeCreateInfoEXT;
    typedef struct VkMutableDescriptorTypeCreateInfoVALVE VkMutableDescriptorTypeCreateInfoVALVE;
    typedef struct VkPhysicalDeviceDepthClipControlFeaturesEXT VkPhysicalDeviceDepthClipControlFeaturesEXT;
    typedef struct VkPhysicalDeviceZeroInitializeDeviceMemoryFeaturesEXT VkPhysicalDeviceZeroInitializeDeviceMemoryFeaturesEXT;
    typedef struct VkBeginCustomResolveInfoEXT VkBeginCustomResolveInfoEXT;
    typedef struct VkPhysicalDeviceCustomResolveFeaturesEXT VkPhysicalDeviceCustomResolveFeaturesEXT;
    typedef struct VkCustomResolveCreateInfoEXT VkCustomResolveCreateInfoEXT;
    typedef struct VkPhysicalDeviceDeviceGeneratedCommandsFeaturesEXT VkPhysicalDeviceDeviceGeneratedCommandsFeaturesEXT;
    typedef struct VkPhysicalDeviceDeviceGeneratedCommandsPropertiesEXT VkPhysicalDeviceDeviceGeneratedCommandsPropertiesEXT;
    typedef struct VkGeneratedCommandsPipelineInfoEXT VkGeneratedCommandsPipelineInfoEXT;
    typedef struct VkGeneratedCommandsShaderInfoEXT VkGeneratedCommandsShaderInfoEXT;
    typedef struct VkGeneratedCommandsMemoryRequirementsInfoEXT VkGeneratedCommandsMemoryRequirementsInfoEXT;
    typedef struct VkIndirectExecutionSetPipelineInfoEXT VkIndirectExecutionSetPipelineInfoEXT;
    typedef struct VkIndirectExecutionSetShaderLayoutInfoEXT VkIndirectExecutionSetShaderLayoutInfoEXT;
    typedef struct VkIndirectExecutionSetShaderInfoEXT VkIndirectExecutionSetShaderInfoEXT;
    typedef union VkIndirectExecutionSetInfoEXT VkIndirectExecutionSetInfoEXT;
    typedef struct VkIndirectExecutionSetCreateInfoEXT VkIndirectExecutionSetCreateInfoEXT;
    typedef struct VkGeneratedCommandsInfoEXT VkGeneratedCommandsInfoEXT;
    typedef struct VkWriteIndirectExecutionSetPipelineEXT VkWriteIndirectExecutionSetPipelineEXT;
    typedef struct VkWriteIndirectExecutionSetShaderEXT VkWriteIndirectExecutionSetShaderEXT;
    typedef struct VkIndirectCommandsLayoutCreateInfoEXT VkIndirectCommandsLayoutCreateInfoEXT;
    typedef struct VkIndirectCommandsLayoutTokenEXT VkIndirectCommandsLayoutTokenEXT;
    typedef struct VkDrawIndirectCountIndirectCommandEXT VkDrawIndirectCountIndirectCommandEXT;
    typedef struct VkIndirectCommandsVertexBufferTokenEXT VkIndirectCommandsVertexBufferTokenEXT;
    typedef struct VkBindVertexBufferIndirectCommandEXT VkBindVertexBufferIndirectCommandEXT;
    typedef struct VkIndirectCommandsIndexBufferTokenEXT VkIndirectCommandsIndexBufferTokenEXT;
    typedef struct VkBindIndexBufferIndirectCommandEXT VkBindIndexBufferIndirectCommandEXT;
    typedef struct VkIndirectCommandsPushConstantTokenEXT VkIndirectCommandsPushConstantTokenEXT;
    typedef struct VkIndirectCommandsExecutionSetTokenEXT VkIndirectCommandsExecutionSetTokenEXT;
    typedef union VkIndirectCommandsTokenDataEXT VkIndirectCommandsTokenDataEXT;
    typedef struct VkPipelineViewportDepthClipControlCreateInfoEXT VkPipelineViewportDepthClipControlCreateInfoEXT;
    typedef struct VkPhysicalDeviceDepthClampControlFeaturesEXT VkPhysicalDeviceDepthClampControlFeaturesEXT;
    typedef struct VkPipelineViewportDepthClampControlCreateInfoEXT VkPipelineViewportDepthClampControlCreateInfoEXT;
    typedef struct VkPhysicalDeviceVertexInputDynamicStateFeaturesEXT VkPhysicalDeviceVertexInputDynamicStateFeaturesEXT;
    typedef struct VkPhysicalDeviceExternalMemoryRDMAFeaturesNV VkPhysicalDeviceExternalMemoryRDMAFeaturesNV;
    typedef struct VkPhysicalDeviceShaderRelaxedExtendedInstructionFeaturesKHR VkPhysicalDeviceShaderRelaxedExtendedInstructionFeaturesKHR;
    typedef struct VkVertexInputBindingDescription2EXT VkVertexInputBindingDescription2EXT;
    typedef struct VkVertexInputAttributeDescription2EXT VkVertexInputAttributeDescription2EXT;
    typedef struct VkPhysicalDeviceColorWriteEnableFeaturesEXT VkPhysicalDeviceColorWriteEnableFeaturesEXT;
    typedef struct VkPipelineColorWriteCreateInfoEXT VkPipelineColorWriteCreateInfoEXT;
    typedef struct VkMemoryBarrier2 VkMemoryBarrier2;
    typedef struct VkMemoryBarrier2KHR VkMemoryBarrier2KHR;
    typedef struct VkImageMemoryBarrier2 VkImageMemoryBarrier2;
    typedef struct VkImageMemoryBarrier2KHR VkImageMemoryBarrier2KHR;
    typedef struct VkBufferMemoryBarrier2 VkBufferMemoryBarrier2;
    typedef struct VkBufferMemoryBarrier2KHR VkBufferMemoryBarrier2KHR;
    typedef struct VkMemoryBarrierAccessFlags3KHR VkMemoryBarrierAccessFlags3KHR;
    typedef struct VkDependencyInfo VkDependencyInfo;
    typedef struct VkDependencyInfoKHR VkDependencyInfoKHR;
    typedef struct VkSemaphoreSubmitInfo VkSemaphoreSubmitInfo;
    typedef struct VkSemaphoreSubmitInfoKHR VkSemaphoreSubmitInfoKHR;
    typedef struct VkCommandBufferSubmitInfo VkCommandBufferSubmitInfo;
    typedef struct VkCommandBufferSubmitInfoKHR VkCommandBufferSubmitInfoKHR;
    typedef struct VkSubmitInfo2 VkSubmitInfo2;
    typedef struct VkSubmitInfo2KHR VkSubmitInfo2KHR;
    typedef struct VkQueueFamilyCheckpointProperties2NV VkQueueFamilyCheckpointProperties2NV;
    typedef struct VkCheckpointData2NV VkCheckpointData2NV;
    typedef struct VkPhysicalDeviceSynchronization2Features VkPhysicalDeviceSynchronization2Features;
    typedef struct VkPhysicalDeviceSynchronization2FeaturesKHR VkPhysicalDeviceSynchronization2FeaturesKHR;
    typedef struct VkPhysicalDeviceUnifiedImageLayoutsFeaturesKHR VkPhysicalDeviceUnifiedImageLayoutsFeaturesKHR;
    typedef struct VkPhysicalDeviceHostImageCopyFeatures VkPhysicalDeviceHostImageCopyFeatures;
    typedef struct VkPhysicalDeviceHostImageCopyFeaturesEXT VkPhysicalDeviceHostImageCopyFeaturesEXT;
    typedef struct VkPhysicalDeviceHostImageCopyProperties VkPhysicalDeviceHostImageCopyProperties;
    typedef struct VkPhysicalDeviceHostImageCopyPropertiesEXT VkPhysicalDeviceHostImageCopyPropertiesEXT;
    typedef struct VkMemoryToImageCopy VkMemoryToImageCopy;
    typedef struct VkMemoryToImageCopyEXT VkMemoryToImageCopyEXT;
    typedef struct VkImageToMemoryCopy VkImageToMemoryCopy;
    typedef struct VkImageToMemoryCopyEXT VkImageToMemoryCopyEXT;
    typedef struct VkCopyMemoryToImageInfo VkCopyMemoryToImageInfo;
    typedef struct VkCopyMemoryToImageInfoEXT VkCopyMemoryToImageInfoEXT;
    typedef struct VkCopyImageToMemoryInfo VkCopyImageToMemoryInfo;
    typedef struct VkCopyImageToMemoryInfoEXT VkCopyImageToMemoryInfoEXT;
    typedef struct VkCopyImageToImageInfo VkCopyImageToImageInfo;
    typedef struct VkCopyImageToImageInfoEXT VkCopyImageToImageInfoEXT;
    typedef struct VkHostImageLayoutTransitionInfo VkHostImageLayoutTransitionInfo;
    typedef struct VkHostImageLayoutTransitionInfoEXT VkHostImageLayoutTransitionInfoEXT;
    typedef struct VkSubresourceHostMemcpySize VkSubresourceHostMemcpySize;
    typedef struct VkSubresourceHostMemcpySizeEXT VkSubresourceHostMemcpySizeEXT;
    typedef struct VkHostImageCopyDevicePerformanceQuery VkHostImageCopyDevicePerformanceQuery;
    typedef struct VkHostImageCopyDevicePerformanceQueryEXT VkHostImageCopyDevicePerformanceQueryEXT;
    typedef struct VkPhysicalDeviceVulkanSC10Properties VkPhysicalDeviceVulkanSC10Properties;
    typedef struct VkPipelinePoolSize VkPipelinePoolSize;
    typedef struct VkDeviceObjectReservationCreateInfo VkDeviceObjectReservationCreateInfo;
    typedef struct VkCommandPoolMemoryReservationCreateInfo VkCommandPoolMemoryReservationCreateInfo;
    typedef struct VkCommandPoolMemoryConsumption VkCommandPoolMemoryConsumption;
    typedef struct VkPhysicalDeviceVulkanSC10Features VkPhysicalDeviceVulkanSC10Features;
    typedef struct VkPhysicalDevicePrimitivesGeneratedQueryFeaturesEXT VkPhysicalDevicePrimitivesGeneratedQueryFeaturesEXT;
    typedef struct VkPhysicalDeviceLegacyDitheringFeaturesEXT VkPhysicalDeviceLegacyDitheringFeaturesEXT;
    typedef struct VkPhysicalDeviceMultisampledRenderToSingleSampledFeaturesEXT VkPhysicalDeviceMultisampledRenderToSingleSampledFeaturesEXT;
    typedef struct VkSurfaceCapabilitiesPresentId2KHR VkSurfaceCapabilitiesPresentId2KHR;
    typedef struct VkSurfaceCapabilitiesPresentWait2KHR VkSurfaceCapabilitiesPresentWait2KHR;
    typedef struct VkSubpassResolvePerformanceQueryEXT VkSubpassResolvePerformanceQueryEXT;
    typedef struct VkMultisampledRenderToSingleSampledInfoEXT VkMultisampledRenderToSingleSampledInfoEXT;
    typedef struct VkPhysicalDevicePipelineProtectedAccessFeatures VkPhysicalDevicePipelineProtectedAccessFeatures;
    typedef struct VkPhysicalDevicePipelineProtectedAccessFeaturesEXT VkPhysicalDevicePipelineProtectedAccessFeaturesEXT;
    typedef struct VkQueueFamilyVideoPropertiesKHR VkQueueFamilyVideoPropertiesKHR;
    typedef struct VkQueueFamilyQueryResultStatusPropertiesKHR VkQueueFamilyQueryResultStatusPropertiesKHR;
    typedef struct VkVideoProfileListInfoKHR VkVideoProfileListInfoKHR;
    typedef struct VkPhysicalDeviceVideoFormatInfoKHR VkPhysicalDeviceVideoFormatInfoKHR;
    typedef struct VkVideoFormatPropertiesKHR VkVideoFormatPropertiesKHR;
    typedef struct VkVideoEncodeQuantizationMapCapabilitiesKHR VkVideoEncodeQuantizationMapCapabilitiesKHR;
    typedef struct VkVideoEncodeH264QuantizationMapCapabilitiesKHR VkVideoEncodeH264QuantizationMapCapabilitiesKHR;
    typedef struct VkVideoEncodeH265QuantizationMapCapabilitiesKHR VkVideoEncodeH265QuantizationMapCapabilitiesKHR;
    typedef struct VkVideoEncodeAV1QuantizationMapCapabilitiesKHR VkVideoEncodeAV1QuantizationMapCapabilitiesKHR;
    typedef struct VkVideoFormatQuantizationMapPropertiesKHR VkVideoFormatQuantizationMapPropertiesKHR;
    typedef struct VkVideoFormatH265QuantizationMapPropertiesKHR VkVideoFormatH265QuantizationMapPropertiesKHR;
    typedef struct VkVideoFormatAV1QuantizationMapPropertiesKHR VkVideoFormatAV1QuantizationMapPropertiesKHR;
    typedef struct VkVideoProfileInfoKHR VkVideoProfileInfoKHR;
    typedef struct VkVideoCapabilitiesKHR VkVideoCapabilitiesKHR;
    typedef struct VkVideoSessionMemoryRequirementsKHR VkVideoSessionMemoryRequirementsKHR;
    typedef struct VkBindVideoSessionMemoryInfoKHR VkBindVideoSessionMemoryInfoKHR;
    typedef struct VkVideoPictureResourceInfoKHR VkVideoPictureResourceInfoKHR;
    typedef struct VkVideoReferenceSlotInfoKHR VkVideoReferenceSlotInfoKHR;
    typedef struct VkVideoDecodeCapabilitiesKHR VkVideoDecodeCapabilitiesKHR;
    typedef struct VkVideoDecodeUsageInfoKHR VkVideoDecodeUsageInfoKHR;
    typedef struct VkVideoDecodeInfoKHR VkVideoDecodeInfoKHR;
    typedef struct VkPhysicalDeviceVideoMaintenance1FeaturesKHR VkPhysicalDeviceVideoMaintenance1FeaturesKHR;
    typedef struct VkPhysicalDeviceVideoMaintenance2FeaturesKHR VkPhysicalDeviceVideoMaintenance2FeaturesKHR;
    typedef struct VkVideoInlineQueryInfoKHR VkVideoInlineQueryInfoKHR;
    typedef struct VkVideoDecodeH264ProfileInfoKHR VkVideoDecodeH264ProfileInfoKHR;
    typedef struct VkVideoDecodeH264CapabilitiesKHR VkVideoDecodeH264CapabilitiesKHR;
    typedef struct VkVideoDecodeH264SessionParametersAddInfoKHR VkVideoDecodeH264SessionParametersAddInfoKHR;
    typedef struct VkVideoDecodeH264SessionParametersCreateInfoKHR VkVideoDecodeH264SessionParametersCreateInfoKHR;
    typedef struct VkVideoDecodeH264InlineSessionParametersInfoKHR VkVideoDecodeH264InlineSessionParametersInfoKHR;
    typedef struct VkVideoDecodeH264PictureInfoKHR VkVideoDecodeH264PictureInfoKHR;
    typedef struct VkVideoDecodeH264DpbSlotInfoKHR VkVideoDecodeH264DpbSlotInfoKHR;
    typedef struct VkVideoDecodeH265ProfileInfoKHR VkVideoDecodeH265ProfileInfoKHR;
    typedef struct VkVideoDecodeH265CapabilitiesKHR VkVideoDecodeH265CapabilitiesKHR;
    typedef struct VkVideoDecodeH265SessionParametersAddInfoKHR VkVideoDecodeH265SessionParametersAddInfoKHR;
    typedef struct VkVideoDecodeH265SessionParametersCreateInfoKHR VkVideoDecodeH265SessionParametersCreateInfoKHR;
    typedef struct VkVideoDecodeH265InlineSessionParametersInfoKHR VkVideoDecodeH265InlineSessionParametersInfoKHR;
    typedef struct VkVideoDecodeH265PictureInfoKHR VkVideoDecodeH265PictureInfoKHR;
    typedef struct VkVideoDecodeH265DpbSlotInfoKHR VkVideoDecodeH265DpbSlotInfoKHR;
    typedef struct VkPhysicalDeviceVideoDecodeVP9FeaturesKHR VkPhysicalDeviceVideoDecodeVP9FeaturesKHR;
    typedef struct VkVideoDecodeVP9ProfileInfoKHR VkVideoDecodeVP9ProfileInfoKHR;
    typedef struct VkVideoDecodeVP9CapabilitiesKHR VkVideoDecodeVP9CapabilitiesKHR;
    typedef struct VkVideoDecodeVP9PictureInfoKHR VkVideoDecodeVP9PictureInfoKHR;
    typedef struct VkVideoDecodeAV1ProfileInfoKHR VkVideoDecodeAV1ProfileInfoKHR;
    typedef struct VkVideoDecodeAV1CapabilitiesKHR VkVideoDecodeAV1CapabilitiesKHR;
    typedef struct VkVideoDecodeAV1SessionParametersCreateInfoKHR VkVideoDecodeAV1SessionParametersCreateInfoKHR;
    typedef struct VkVideoDecodeAV1InlineSessionParametersInfoKHR VkVideoDecodeAV1InlineSessionParametersInfoKHR;
    typedef struct VkVideoDecodeAV1PictureInfoKHR VkVideoDecodeAV1PictureInfoKHR;
    typedef struct VkVideoDecodeAV1DpbSlotInfoKHR VkVideoDecodeAV1DpbSlotInfoKHR;
    typedef struct VkVideoSessionCreateInfoKHR VkVideoSessionCreateInfoKHR;
    typedef struct VkVideoSessionParametersCreateInfoKHR VkVideoSessionParametersCreateInfoKHR;
    typedef struct VkVideoSessionParametersUpdateInfoKHR VkVideoSessionParametersUpdateInfoKHR;
    typedef struct VkVideoEncodeSessionParametersGetInfoKHR VkVideoEncodeSessionParametersGetInfoKHR;
    typedef struct VkVideoEncodeSessionParametersFeedbackInfoKHR VkVideoEncodeSessionParametersFeedbackInfoKHR;
    typedef struct VkVideoBeginCodingInfoKHR VkVideoBeginCodingInfoKHR;
    typedef struct VkVideoEndCodingInfoKHR VkVideoEndCodingInfoKHR;
    typedef struct VkVideoCodingControlInfoKHR VkVideoCodingControlInfoKHR;
    typedef struct VkVideoEncodeUsageInfoKHR VkVideoEncodeUsageInfoKHR;
    typedef struct VkVideoEncodeInfoKHR VkVideoEncodeInfoKHR;
    typedef struct VkVideoEncodeQuantizationMapInfoKHR VkVideoEncodeQuantizationMapInfoKHR;
    typedef struct VkVideoEncodeQuantizationMapSessionParametersCreateInfoKHR VkVideoEncodeQuantizationMapSessionParametersCreateInfoKHR;
    typedef struct VkPhysicalDeviceVideoEncodeQuantizationMapFeaturesKHR VkPhysicalDeviceVideoEncodeQuantizationMapFeaturesKHR;
    typedef struct VkQueryPoolVideoEncodeFeedbackCreateInfoKHR VkQueryPoolVideoEncodeFeedbackCreateInfoKHR;
    typedef struct VkVideoEncodeQualityLevelInfoKHR VkVideoEncodeQualityLevelInfoKHR;
    typedef struct VkPhysicalDeviceVideoEncodeQualityLevelInfoKHR VkPhysicalDeviceVideoEncodeQualityLevelInfoKHR;
    typedef struct VkVideoEncodeQualityLevelPropertiesKHR VkVideoEncodeQualityLevelPropertiesKHR;
    typedef struct VkVideoEncodeRateControlInfoKHR VkVideoEncodeRateControlInfoKHR;
    typedef struct VkVideoEncodeRateControlLayerInfoKHR VkVideoEncodeRateControlLayerInfoKHR;
    typedef struct VkVideoEncodeCapabilitiesKHR VkVideoEncodeCapabilitiesKHR;
    typedef struct VkVideoEncodeH264CapabilitiesKHR VkVideoEncodeH264CapabilitiesKHR;
    typedef struct VkVideoEncodeH264QualityLevelPropertiesKHR VkVideoEncodeH264QualityLevelPropertiesKHR;
    typedef struct VkVideoEncodeH264SessionCreateInfoKHR VkVideoEncodeH264SessionCreateInfoKHR;
    typedef struct VkVideoEncodeH264SessionParametersAddInfoKHR VkVideoEncodeH264SessionParametersAddInfoKHR;
    typedef struct VkVideoEncodeH264SessionParametersCreateInfoKHR VkVideoEncodeH264SessionParametersCreateInfoKHR;
    typedef struct VkVideoEncodeH264SessionParametersGetInfoKHR VkVideoEncodeH264SessionParametersGetInfoKHR;
    typedef struct VkVideoEncodeH264SessionParametersFeedbackInfoKHR VkVideoEncodeH264SessionParametersFeedbackInfoKHR;
    typedef struct VkVideoEncodeH264DpbSlotInfoKHR VkVideoEncodeH264DpbSlotInfoKHR;
    typedef struct VkVideoEncodeH264PictureInfoKHR VkVideoEncodeH264PictureInfoKHR;
    typedef struct VkVideoEncodeH264ProfileInfoKHR VkVideoEncodeH264ProfileInfoKHR;
    typedef struct VkVideoEncodeH264NaluSliceInfoKHR VkVideoEncodeH264NaluSliceInfoKHR;
    typedef struct VkVideoEncodeH264RateControlInfoKHR VkVideoEncodeH264RateControlInfoKHR;
    typedef struct VkVideoEncodeH264QpKHR VkVideoEncodeH264QpKHR;
    typedef struct VkVideoEncodeH264FrameSizeKHR VkVideoEncodeH264FrameSizeKHR;
    typedef struct VkVideoEncodeH264GopRemainingFrameInfoKHR VkVideoEncodeH264GopRemainingFrameInfoKHR;
    typedef struct VkVideoEncodeH264RateControlLayerInfoKHR VkVideoEncodeH264RateControlLayerInfoKHR;
    typedef struct VkVideoEncodeH265CapabilitiesKHR VkVideoEncodeH265CapabilitiesKHR;
    typedef struct VkVideoEncodeH265QualityLevelPropertiesKHR VkVideoEncodeH265QualityLevelPropertiesKHR;
    typedef struct VkVideoEncodeH265SessionCreateInfoKHR VkVideoEncodeH265SessionCreateInfoKHR;
    typedef struct VkVideoEncodeH265SessionParametersAddInfoKHR VkVideoEncodeH265SessionParametersAddInfoKHR;
    typedef struct VkVideoEncodeH265SessionParametersCreateInfoKHR VkVideoEncodeH265SessionParametersCreateInfoKHR;
    typedef struct VkVideoEncodeH265SessionParametersGetInfoKHR VkVideoEncodeH265SessionParametersGetInfoKHR;
    typedef struct VkVideoEncodeH265SessionParametersFeedbackInfoKHR VkVideoEncodeH265SessionParametersFeedbackInfoKHR;
    typedef struct VkVideoEncodeH265PictureInfoKHR VkVideoEncodeH265PictureInfoKHR;
    typedef struct VkVideoEncodeH265NaluSliceSegmentInfoKHR VkVideoEncodeH265NaluSliceSegmentInfoKHR;
    typedef struct VkVideoEncodeH265RateControlInfoKHR VkVideoEncodeH265RateControlInfoKHR;
    typedef struct VkVideoEncodeH265QpKHR VkVideoEncodeH265QpKHR;
    typedef struct VkVideoEncodeH265FrameSizeKHR VkVideoEncodeH265FrameSizeKHR;
    typedef struct VkVideoEncodeH265GopRemainingFrameInfoKHR VkVideoEncodeH265GopRemainingFrameInfoKHR;
    typedef struct VkVideoEncodeH265RateControlLayerInfoKHR VkVideoEncodeH265RateControlLayerInfoKHR;
    typedef struct VkVideoEncodeH265ProfileInfoKHR VkVideoEncodeH265ProfileInfoKHR;
    typedef struct VkVideoEncodeH265DpbSlotInfoKHR VkVideoEncodeH265DpbSlotInfoKHR;
    typedef struct VkVideoEncodeAV1CapabilitiesKHR VkVideoEncodeAV1CapabilitiesKHR;
    typedef struct VkVideoEncodeAV1QualityLevelPropertiesKHR VkVideoEncodeAV1QualityLevelPropertiesKHR;
    typedef struct VkPhysicalDeviceVideoEncodeAV1FeaturesKHR VkPhysicalDeviceVideoEncodeAV1FeaturesKHR;
    typedef struct VkVideoEncodeAV1SessionCreateInfoKHR VkVideoEncodeAV1SessionCreateInfoKHR;
    typedef struct VkVideoEncodeAV1SessionParametersCreateInfoKHR VkVideoEncodeAV1SessionParametersCreateInfoKHR;
    typedef struct VkVideoEncodeAV1DpbSlotInfoKHR VkVideoEncodeAV1DpbSlotInfoKHR;
    typedef struct VkVideoEncodeAV1PictureInfoKHR VkVideoEncodeAV1PictureInfoKHR;
    typedef struct VkVideoEncodeAV1ProfileInfoKHR VkVideoEncodeAV1ProfileInfoKHR;
    typedef struct VkVideoEncodeAV1RateControlInfoKHR VkVideoEncodeAV1RateControlInfoKHR;
    typedef struct VkVideoEncodeAV1QIndexKHR VkVideoEncodeAV1QIndexKHR;
    typedef struct VkVideoEncodeAV1FrameSizeKHR VkVideoEncodeAV1FrameSizeKHR;
    typedef struct VkVideoEncodeAV1GopRemainingFrameInfoKHR VkVideoEncodeAV1GopRemainingFrameInfoKHR;
    typedef struct VkVideoEncodeAV1RateControlLayerInfoKHR VkVideoEncodeAV1RateControlLayerInfoKHR;
    typedef struct VkPhysicalDeviceInheritedViewportScissorFeaturesNV VkPhysicalDeviceInheritedViewportScissorFeaturesNV;
    typedef struct VkCommandBufferInheritanceViewportScissorInfoNV VkCommandBufferInheritanceViewportScissorInfoNV;
    typedef struct VkPhysicalDeviceYcbcr2Plane444FormatsFeaturesEXT VkPhysicalDeviceYcbcr2Plane444FormatsFeaturesEXT;
    typedef struct VkPhysicalDeviceProvokingVertexFeaturesEXT VkPhysicalDeviceProvokingVertexFeaturesEXT;
    typedef struct VkPhysicalDeviceProvokingVertexPropertiesEXT VkPhysicalDeviceProvokingVertexPropertiesEXT;
    typedef struct VkPipelineRasterizationProvokingVertexStateCreateInfoEXT VkPipelineRasterizationProvokingVertexStateCreateInfoEXT;
    typedef struct VkVideoEncodeIntraRefreshCapabilitiesKHR VkVideoEncodeIntraRefreshCapabilitiesKHR;
    typedef struct VkVideoEncodeSessionIntraRefreshCreateInfoKHR VkVideoEncodeSessionIntraRefreshCreateInfoKHR;
    typedef struct VkVideoEncodeIntraRefreshInfoKHR VkVideoEncodeIntraRefreshInfoKHR;
    typedef struct VkVideoReferenceIntraRefreshInfoKHR VkVideoReferenceIntraRefreshInfoKHR;
    typedef struct VkPhysicalDeviceVideoEncodeIntraRefreshFeaturesKHR VkPhysicalDeviceVideoEncodeIntraRefreshFeaturesKHR;
    typedef struct VkCuModuleCreateInfoNVX VkCuModuleCreateInfoNVX;
    typedef struct VkCuModuleTexturingModeCreateInfoNVX VkCuModuleTexturingModeCreateInfoNVX;
    typedef struct VkCuFunctionCreateInfoNVX VkCuFunctionCreateInfoNVX;
    typedef struct VkCuLaunchInfoNVX VkCuLaunchInfoNVX;
    typedef struct VkPhysicalDeviceDescriptorBufferFeaturesEXT VkPhysicalDeviceDescriptorBufferFeaturesEXT;
    typedef struct VkPhysicalDeviceDescriptorBufferPropertiesEXT VkPhysicalDeviceDescriptorBufferPropertiesEXT;
    typedef struct VkPhysicalDeviceDescriptorBufferDensityMapPropertiesEXT VkPhysicalDeviceDescriptorBufferDensityMapPropertiesEXT;
    typedef struct VkDescriptorAddressInfoEXT VkDescriptorAddressInfoEXT;
    typedef struct VkDescriptorBufferBindingInfoEXT VkDescriptorBufferBindingInfoEXT;
    typedef struct VkDescriptorBufferBindingPushDescriptorBufferHandleEXT VkDescriptorBufferBindingPushDescriptorBufferHandleEXT;
    typedef union VkDescriptorDataEXT VkDescriptorDataEXT;
    typedef struct VkDescriptorGetInfoEXT VkDescriptorGetInfoEXT;
    typedef struct VkBufferCaptureDescriptorDataInfoEXT VkBufferCaptureDescriptorDataInfoEXT;
    typedef struct VkImageCaptureDescriptorDataInfoEXT VkImageCaptureDescriptorDataInfoEXT;
    typedef struct VkImageViewCaptureDescriptorDataInfoEXT VkImageViewCaptureDescriptorDataInfoEXT;
    typedef struct VkSamplerCaptureDescriptorDataInfoEXT VkSamplerCaptureDescriptorDataInfoEXT;
    typedef struct VkAccelerationStructureCaptureDescriptorDataInfoEXT VkAccelerationStructureCaptureDescriptorDataInfoEXT;
    typedef struct VkOpaqueCaptureDescriptorDataCreateInfoEXT VkOpaqueCaptureDescriptorDataCreateInfoEXT;
    typedef struct VkPhysicalDeviceShaderIntegerDotProductFeatures VkPhysicalDeviceShaderIntegerDotProductFeatures;
    typedef struct VkPhysicalDeviceShaderIntegerDotProductFeaturesKHR VkPhysicalDeviceShaderIntegerDotProductFeaturesKHR;
    typedef struct VkPhysicalDeviceShaderIntegerDotProductProperties VkPhysicalDeviceShaderIntegerDotProductProperties;
    typedef struct VkPhysicalDeviceShaderIntegerDotProductPropertiesKHR VkPhysicalDeviceShaderIntegerDotProductPropertiesKHR;
    typedef struct VkPhysicalDeviceDrmPropertiesEXT VkPhysicalDeviceDrmPropertiesEXT;
    typedef struct VkPhysicalDeviceFragmentShaderBarycentricFeaturesKHR VkPhysicalDeviceFragmentShaderBarycentricFeaturesKHR;
    typedef struct VkPhysicalDeviceFragmentShaderBarycentricPropertiesKHR VkPhysicalDeviceFragmentShaderBarycentricPropertiesKHR;
    typedef struct VkPhysicalDeviceShaderFmaFeaturesKHR VkPhysicalDeviceShaderFmaFeaturesKHR;
    typedef struct VkPhysicalDeviceRayTracingMotionBlurFeaturesNV VkPhysicalDeviceRayTracingMotionBlurFeaturesNV;
    typedef struct VkPhysicalDeviceRayTracingValidationFeaturesNV VkPhysicalDeviceRayTracingValidationFeaturesNV;
    typedef struct VkPhysicalDeviceRayTracingLinearSweptSpheresFeaturesNV VkPhysicalDeviceRayTracingLinearSweptSpheresFeaturesNV;
    typedef struct VkAccelerationStructureGeometryMotionTrianglesDataNV VkAccelerationStructureGeometryMotionTrianglesDataNV;
    typedef struct VkAccelerationStructureMotionInfoNV VkAccelerationStructureMotionInfoNV;
    typedef struct VkSRTDataNV VkSRTDataNV;
    typedef struct VkAccelerationStructureSRTMotionInstanceNV VkAccelerationStructureSRTMotionInstanceNV;
    typedef struct VkAccelerationStructureMatrixMotionInstanceNV VkAccelerationStructureMatrixMotionInstanceNV;
    typedef union VkAccelerationStructureMotionInstanceDataNV VkAccelerationStructureMotionInstanceDataNV;
    typedef struct VkAccelerationStructureMotionInstanceNV VkAccelerationStructureMotionInstanceNV;
    typedef struct VkMemoryGetRemoteAddressInfoNV VkMemoryGetRemoteAddressInfoNV;
    typedef struct VkImportMemoryBufferCollectionFUCHSIA VkImportMemoryBufferCollectionFUCHSIA;
    typedef struct VkBufferCollectionImageCreateInfoFUCHSIA VkBufferCollectionImageCreateInfoFUCHSIA;
    typedef struct VkBufferCollectionBufferCreateInfoFUCHSIA VkBufferCollectionBufferCreateInfoFUCHSIA;
    typedef struct VkBufferCollectionCreateInfoFUCHSIA VkBufferCollectionCreateInfoFUCHSIA;
    typedef struct VkBufferCollectionPropertiesFUCHSIA VkBufferCollectionPropertiesFUCHSIA;
    typedef struct VkBufferConstraintsInfoFUCHSIA VkBufferConstraintsInfoFUCHSIA;
    typedef struct VkSysmemColorSpaceFUCHSIA VkSysmemColorSpaceFUCHSIA;
    typedef struct VkImageFormatConstraintsInfoFUCHSIA VkImageFormatConstraintsInfoFUCHSIA;
    typedef struct VkImageConstraintsInfoFUCHSIA VkImageConstraintsInfoFUCHSIA;
    typedef struct VkBufferCollectionConstraintsInfoFUCHSIA VkBufferCollectionConstraintsInfoFUCHSIA;
    typedef struct VkCudaModuleNV_T* VkCudaModuleNV;
    typedef struct VkCudaFunctionNV_T* VkCudaFunctionNV;
    typedef struct VkCudaModuleCreateInfoNV VkCudaModuleCreateInfoNV;
    typedef struct VkCudaFunctionCreateInfoNV VkCudaFunctionCreateInfoNV;
    typedef struct VkCudaLaunchInfoNV VkCudaLaunchInfoNV;
    typedef struct VkPhysicalDeviceRGBA10X6FormatsFeaturesEXT VkPhysicalDeviceRGBA10X6FormatsFeaturesEXT;
    typedef struct VkFormatProperties3 VkFormatProperties3;
    typedef struct VkFormatProperties3KHR VkFormatProperties3KHR;
    typedef struct VkDrmFormatModifierPropertiesList2EXT VkDrmFormatModifierPropertiesList2EXT;
    typedef struct VkDrmFormatModifierProperties2EXT VkDrmFormatModifierProperties2EXT;
    typedef struct VkAndroidHardwareBufferFormatProperties2ANDROID VkAndroidHardwareBufferFormatProperties2ANDROID;
    typedef struct VkPipelineRenderingCreateInfo VkPipelineRenderingCreateInfo;
    typedef struct VkPipelineRenderingCreateInfoKHR VkPipelineRenderingCreateInfoKHR;
    typedef struct VkRenderingInfo VkRenderingInfo;
    typedef struct VkRenderingInfoKHR VkRenderingInfoKHR;
    typedef struct VkRenderingEndInfoKHR VkRenderingEndInfoKHR;
    typedef struct VkRenderingEndInfoEXT VkRenderingEndInfoEXT;
    typedef struct VkRenderingAttachmentInfo VkRenderingAttachmentInfo;
    typedef struct VkRenderingAttachmentInfoKHR VkRenderingAttachmentInfoKHR;
    typedef struct VkRenderingFragmentShadingRateAttachmentInfoKHR VkRenderingFragmentShadingRateAttachmentInfoKHR;
    typedef struct VkRenderingFragmentDensityMapAttachmentInfoEXT VkRenderingFragmentDensityMapAttachmentInfoEXT;
    typedef struct VkPhysicalDeviceDynamicRenderingFeatures VkPhysicalDeviceDynamicRenderingFeatures;
    typedef struct VkPhysicalDeviceDynamicRenderingFeaturesKHR VkPhysicalDeviceDynamicRenderingFeaturesKHR;
    typedef struct VkCommandBufferInheritanceRenderingInfo VkCommandBufferInheritanceRenderingInfo;
    typedef struct VkCommandBufferInheritanceRenderingInfoKHR VkCommandBufferInheritanceRenderingInfoKHR;
    typedef struct VkAttachmentSampleCountInfoAMD VkAttachmentSampleCountInfoAMD;
    typedef struct VkAttachmentSampleCountInfoNV VkAttachmentSampleCountInfoNV;
    typedef struct VkMultiviewPerViewAttributesInfoNVX VkMultiviewPerViewAttributesInfoNVX;
    typedef struct VkPhysicalDeviceImageViewMinLodFeaturesEXT VkPhysicalDeviceImageViewMinLodFeaturesEXT;
    typedef struct VkImageViewMinLodCreateInfoEXT VkImageViewMinLodCreateInfoEXT;
    typedef struct VkPhysicalDeviceRasterizationOrderAttachmentAccessFeaturesEXT VkPhysicalDeviceRasterizationOrderAttachmentAccessFeaturesEXT;
    typedef struct VkPhysicalDeviceRasterizationOrderAttachmentAccessFeaturesARM VkPhysicalDeviceRasterizationOrderAttachmentAccessFeaturesARM;
    typedef struct VkPhysicalDeviceLinearColorAttachmentFeaturesNV VkPhysicalDeviceLinearColorAttachmentFeaturesNV;
    typedef struct VkPhysicalDeviceGraphicsPipelineLibraryFeaturesEXT VkPhysicalDeviceGraphicsPipelineLibraryFeaturesEXT;
    typedef struct VkPhysicalDevicePipelineBinaryFeaturesKHR VkPhysicalDevicePipelineBinaryFeaturesKHR;
    typedef struct VkDevicePipelineBinaryInternalCacheControlKHR VkDevicePipelineBinaryInternalCacheControlKHR;
    typedef struct VkPhysicalDevicePipelineBinaryPropertiesKHR VkPhysicalDevicePipelineBinaryPropertiesKHR;
    typedef struct VkPhysicalDeviceGraphicsPipelineLibraryPropertiesEXT VkPhysicalDeviceGraphicsPipelineLibraryPropertiesEXT;
    typedef struct VkGraphicsPipelineLibraryCreateInfoEXT VkGraphicsPipelineLibraryCreateInfoEXT;
    typedef struct VkPhysicalDeviceDescriptorSetHostMappingFeaturesVALVE VkPhysicalDeviceDescriptorSetHostMappingFeaturesVALVE;
    typedef struct VkDescriptorSetBindingReferenceVALVE VkDescriptorSetBindingReferenceVALVE;
    typedef struct VkDescriptorSetLayoutHostMappingInfoVALVE VkDescriptorSetLayoutHostMappingInfoVALVE;
    typedef struct VkPhysicalDeviceNestedCommandBufferFeaturesEXT VkPhysicalDeviceNestedCommandBufferFeaturesEXT;
    typedef struct VkPhysicalDeviceNestedCommandBufferPropertiesEXT VkPhysicalDeviceNestedCommandBufferPropertiesEXT;
    typedef struct VkPhysicalDeviceShaderModuleIdentifierFeaturesEXT VkPhysicalDeviceShaderModuleIdentifierFeaturesEXT;
    typedef struct VkPhysicalDeviceShaderModuleIdentifierPropertiesEXT VkPhysicalDeviceShaderModuleIdentifierPropertiesEXT;
    typedef struct VkPipelineShaderStageModuleIdentifierCreateInfoEXT VkPipelineShaderStageModuleIdentifierCreateInfoEXT;
    typedef struct VkShaderModuleIdentifierEXT VkShaderModuleIdentifierEXT;
    typedef struct VkImageCompressionControlEXT VkImageCompressionControlEXT;
    typedef struct VkPhysicalDeviceImageCompressionControlFeaturesEXT VkPhysicalDeviceImageCompressionControlFeaturesEXT;
    typedef struct VkImageCompressionPropertiesEXT VkImageCompressionPropertiesEXT;
    typedef struct VkPhysicalDeviceImageCompressionControlSwapchainFeaturesEXT VkPhysicalDeviceImageCompressionControlSwapchainFeaturesEXT;
    typedef struct VkImageSubresource2 VkImageSubresource2;
    typedef struct VkImageSubresource2KHR VkImageSubresource2KHR;
    typedef struct VkImageSubresource2EXT VkImageSubresource2EXT;
    typedef struct VkSubresourceLayout2 VkSubresourceLayout2;
    typedef struct VkSubresourceLayout2KHR VkSubresourceLayout2KHR;
    typedef struct VkSubresourceLayout2EXT VkSubresourceLayout2EXT;
    typedef struct VkRenderPassCreationControlEXT VkRenderPassCreationControlEXT;
    typedef struct VkRenderPassCreationFeedbackInfoEXT VkRenderPassCreationFeedbackInfoEXT;
    typedef struct VkRenderPassCreationFeedbackCreateInfoEXT VkRenderPassCreationFeedbackCreateInfoEXT;
    typedef struct VkRenderPassSubpassFeedbackInfoEXT VkRenderPassSubpassFeedbackInfoEXT;
    typedef struct VkRenderPassSubpassFeedbackCreateInfoEXT VkRenderPassSubpassFeedbackCreateInfoEXT;
    typedef struct VkPhysicalDeviceSubpassMergeFeedbackFeaturesEXT VkPhysicalDeviceSubpassMergeFeedbackFeaturesEXT;
    typedef struct VkMicromapBuildInfoEXT VkMicromapBuildInfoEXT;
    typedef struct VkMicromapCreateInfoEXT VkMicromapCreateInfoEXT;
    typedef struct VkMicromapVersionInfoEXT VkMicromapVersionInfoEXT;
    typedef struct VkCopyMicromapInfoEXT VkCopyMicromapInfoEXT;
    typedef struct VkCopyMicromapToMemoryInfoEXT VkCopyMicromapToMemoryInfoEXT;
    typedef struct VkCopyMemoryToMicromapInfoEXT VkCopyMemoryToMicromapInfoEXT;
    typedef struct VkMicromapBuildSizesInfoEXT VkMicromapBuildSizesInfoEXT;
    typedef struct VkMicromapUsageEXT VkMicromapUsageEXT;
    typedef struct VkMicromapTriangleEXT VkMicromapTriangleEXT;
    typedef struct VkPhysicalDeviceOpacityMicromapFeaturesEXT VkPhysicalDeviceOpacityMicromapFeaturesEXT;
    typedef struct VkPhysicalDeviceOpacityMicromapPropertiesEXT VkPhysicalDeviceOpacityMicromapPropertiesEXT;
    typedef struct VkAccelerationStructureTrianglesOpacityMicromapEXT VkAccelerationStructureTrianglesOpacityMicromapEXT;
    typedef struct VkPhysicalDeviceDisplacementMicromapFeaturesNV VkPhysicalDeviceDisplacementMicromapFeaturesNV;
    typedef struct VkPhysicalDeviceDisplacementMicromapPropertiesNV VkPhysicalDeviceDisplacementMicromapPropertiesNV;
    typedef struct VkAccelerationStructureTrianglesDisplacementMicromapNV VkAccelerationStructureTrianglesDisplacementMicromapNV;
    typedef struct VkPipelinePropertiesIdentifierEXT VkPipelinePropertiesIdentifierEXT;
    typedef struct VkPhysicalDevicePipelinePropertiesFeaturesEXT VkPhysicalDevicePipelinePropertiesFeaturesEXT;
    typedef struct VkPhysicalDeviceShaderEarlyAndLateFragmentTestsFeaturesAMD VkPhysicalDeviceShaderEarlyAndLateFragmentTestsFeaturesAMD;
    typedef struct VkExternalMemoryAcquireUnmodifiedEXT VkExternalMemoryAcquireUnmodifiedEXT;
    typedef struct VkExportMetalObjectCreateInfoEXT VkExportMetalObjectCreateInfoEXT;
    typedef struct VkExportMetalObjectsInfoEXT VkExportMetalObjectsInfoEXT;
    typedef struct VkExportMetalDeviceInfoEXT VkExportMetalDeviceInfoEXT;
    typedef struct VkExportMetalCommandQueueInfoEXT VkExportMetalCommandQueueInfoEXT;
    typedef struct VkExportMetalBufferInfoEXT VkExportMetalBufferInfoEXT;
    typedef struct VkImportMetalBufferInfoEXT VkImportMetalBufferInfoEXT;
    typedef struct VkExportMetalTextureInfoEXT VkExportMetalTextureInfoEXT;
    typedef struct VkImportMetalTextureInfoEXT VkImportMetalTextureInfoEXT;
    typedef struct VkExportMetalIOSurfaceInfoEXT VkExportMetalIOSurfaceInfoEXT;
    typedef struct VkImportMetalIOSurfaceInfoEXT VkImportMetalIOSurfaceInfoEXT;
    typedef struct VkExportMetalSharedEventInfoEXT VkExportMetalSharedEventInfoEXT;
    typedef struct VkImportMetalSharedEventInfoEXT VkImportMetalSharedEventInfoEXT;
    typedef struct VkPhysicalDeviceNonSeamlessCubeMapFeaturesEXT VkPhysicalDeviceNonSeamlessCubeMapFeaturesEXT;
    typedef struct VkPhysicalDevicePipelineRobustnessFeatures VkPhysicalDevicePipelineRobustnessFeatures;
    typedef struct VkPhysicalDevicePipelineRobustnessFeaturesEXT VkPhysicalDevicePipelineRobustnessFeaturesEXT;
    typedef struct VkPipelineRobustnessCreateInfo VkPipelineRobustnessCreateInfo;
    typedef struct VkPipelineRobustnessCreateInfoEXT VkPipelineRobustnessCreateInfoEXT;
    typedef struct VkPhysicalDevicePipelineRobustnessProperties VkPhysicalDevicePipelineRobustnessProperties;
    typedef struct VkPhysicalDevicePipelineRobustnessPropertiesEXT VkPhysicalDevicePipelineRobustnessPropertiesEXT;
    typedef struct VkImageViewSampleWeightCreateInfoQCOM VkImageViewSampleWeightCreateInfoQCOM;
    typedef struct VkPhysicalDeviceImageProcessingFeaturesQCOM VkPhysicalDeviceImageProcessingFeaturesQCOM;
    typedef struct VkPhysicalDeviceImageProcessingPropertiesQCOM VkPhysicalDeviceImageProcessingPropertiesQCOM;
    typedef struct VkPhysicalDeviceTilePropertiesFeaturesQCOM VkPhysicalDeviceTilePropertiesFeaturesQCOM;
    typedef struct VkTilePropertiesQCOM VkTilePropertiesQCOM;
    typedef struct VkTileMemoryBindInfoQCOM VkTileMemoryBindInfoQCOM;
    typedef struct VkPhysicalDeviceAmigoProfilingFeaturesSEC VkPhysicalDeviceAmigoProfilingFeaturesSEC;
    typedef struct VkAmigoProfilingSubmitInfoSEC VkAmigoProfilingSubmitInfoSEC;
    typedef struct VkPhysicalDeviceAttachmentFeedbackLoopLayoutFeaturesEXT VkPhysicalDeviceAttachmentFeedbackLoopLayoutFeaturesEXT;
    typedef struct VkPhysicalDeviceDepthClampZeroOneFeaturesEXT VkPhysicalDeviceDepthClampZeroOneFeaturesEXT;
    typedef struct VkAttachmentFeedbackLoopInfoEXT VkAttachmentFeedbackLoopInfoEXT;
    typedef struct VkPhysicalDeviceAddressBindingReportFeaturesEXT VkPhysicalDeviceAddressBindingReportFeaturesEXT;
    typedef struct VkRenderingAttachmentFlagsInfoKHR VkRenderingAttachmentFlagsInfoKHR;
    typedef struct VkResolveImageModeInfoKHR VkResolveImageModeInfoKHR;
    typedef struct VkDeviceAddressBindingCallbackDataEXT VkDeviceAddressBindingCallbackDataEXT;
    typedef struct VkPhysicalDeviceOpticalFlowFeaturesNV VkPhysicalDeviceOpticalFlowFeaturesNV;
    typedef struct VkPhysicalDeviceOpticalFlowPropertiesNV VkPhysicalDeviceOpticalFlowPropertiesNV;
    typedef struct VkOpticalFlowImageFormatInfoNV VkOpticalFlowImageFormatInfoNV;
    typedef struct VkOpticalFlowImageFormatPropertiesNV VkOpticalFlowImageFormatPropertiesNV;
    typedef struct VkOpticalFlowSessionCreateInfoNV VkOpticalFlowSessionCreateInfoNV;
    typedef struct VkOpticalFlowSessionCreatePrivateDataInfoNV VkOpticalFlowSessionCreatePrivateDataInfoNV;
    typedef struct VkOpticalFlowExecuteInfoNV VkOpticalFlowExecuteInfoNV;
    typedef struct VkPhysicalDeviceFaultFeaturesEXT VkPhysicalDeviceFaultFeaturesEXT;
    typedef struct VkDeviceFaultAddressInfoEXT VkDeviceFaultAddressInfoEXT;
    typedef struct VkDeviceFaultVendorInfoEXT VkDeviceFaultVendorInfoEXT;
    typedef struct VkDeviceFaultCountsEXT VkDeviceFaultCountsEXT;
    typedef struct VkDeviceFaultInfoEXT VkDeviceFaultInfoEXT;
    typedef struct VkDeviceFaultVendorBinaryHeaderVersionOneEXT VkDeviceFaultVendorBinaryHeaderVersionOneEXT;
    typedef struct VkPhysicalDevicePipelineLibraryGroupHandlesFeaturesEXT VkPhysicalDevicePipelineLibraryGroupHandlesFeaturesEXT;
    typedef struct VkDepthBiasInfoEXT VkDepthBiasInfoEXT;
    typedef struct VkDepthBiasRepresentationInfoEXT VkDepthBiasRepresentationInfoEXT;
    typedef struct VkDecompressMemoryRegionNV VkDecompressMemoryRegionNV;
    typedef struct VkDecompressMemoryRegionEXT VkDecompressMemoryRegionEXT;
    typedef struct VkDecompressMemoryInfoEXT VkDecompressMemoryInfoEXT;
    typedef struct VkPhysicalDeviceShaderCoreBuiltinsPropertiesARM VkPhysicalDeviceShaderCoreBuiltinsPropertiesARM;
    typedef struct VkPhysicalDeviceShaderCoreBuiltinsFeaturesARM VkPhysicalDeviceShaderCoreBuiltinsFeaturesARM;
    typedef struct VkFrameBoundaryEXT VkFrameBoundaryEXT;
    typedef struct VkPhysicalDeviceFrameBoundaryFeaturesEXT VkPhysicalDeviceFrameBoundaryFeaturesEXT;
    typedef struct VkPhysicalDeviceDynamicRenderingUnusedAttachmentsFeaturesEXT VkPhysicalDeviceDynamicRenderingUnusedAttachmentsFeaturesEXT;
    typedef struct VkPhysicalDeviceInternallySynchronizedQueuesFeaturesKHR VkPhysicalDeviceInternallySynchronizedQueuesFeaturesKHR;
    typedef struct VkSurfacePresentModeKHR VkSurfacePresentModeKHR;
    typedef struct VkSurfacePresentModeEXT VkSurfacePresentModeEXT;
    typedef struct VkSurfacePresentScalingCapabilitiesKHR VkSurfacePresentScalingCapabilitiesKHR;
    typedef struct VkSurfacePresentScalingCapabilitiesEXT VkSurfacePresentScalingCapabilitiesEXT;
    typedef struct VkSurfacePresentModeCompatibilityKHR VkSurfacePresentModeCompatibilityKHR;
    typedef struct VkSurfacePresentModeCompatibilityEXT VkSurfacePresentModeCompatibilityEXT;
    typedef struct VkPhysicalDeviceSwapchainMaintenance1FeaturesKHR VkPhysicalDeviceSwapchainMaintenance1FeaturesKHR;
    typedef struct VkPhysicalDeviceSwapchainMaintenance1FeaturesEXT VkPhysicalDeviceSwapchainMaintenance1FeaturesEXT;
    typedef struct VkSwapchainPresentFenceInfoKHR VkSwapchainPresentFenceInfoKHR;
    typedef struct VkSwapchainPresentFenceInfoEXT VkSwapchainPresentFenceInfoEXT;
    typedef struct VkSwapchainPresentModesCreateInfoKHR VkSwapchainPresentModesCreateInfoKHR;
    typedef struct VkSwapchainPresentModesCreateInfoEXT VkSwapchainPresentModesCreateInfoEXT;
    typedef struct VkSwapchainPresentModeInfoKHR VkSwapchainPresentModeInfoKHR;
    typedef struct VkSwapchainPresentModeInfoEXT VkSwapchainPresentModeInfoEXT;
    typedef struct VkSwapchainPresentScalingCreateInfoKHR VkSwapchainPresentScalingCreateInfoKHR;
    typedef struct VkSwapchainPresentScalingCreateInfoEXT VkSwapchainPresentScalingCreateInfoEXT;
    typedef struct VkReleaseSwapchainImagesInfoKHR VkReleaseSwapchainImagesInfoKHR;
    typedef struct VkReleaseSwapchainImagesInfoEXT VkReleaseSwapchainImagesInfoEXT;
    typedef struct VkPhysicalDeviceDepthBiasControlFeaturesEXT VkPhysicalDeviceDepthBiasControlFeaturesEXT;
    typedef struct VkPhysicalDeviceRayTracingInvocationReorderFeaturesEXT VkPhysicalDeviceRayTracingInvocationReorderFeaturesEXT;
    typedef struct VkPhysicalDeviceRayTracingInvocationReorderFeaturesNV VkPhysicalDeviceRayTracingInvocationReorderFeaturesNV;
    typedef struct VkPhysicalDeviceRayTracingInvocationReorderPropertiesEXT VkPhysicalDeviceRayTracingInvocationReorderPropertiesEXT;
    typedef struct VkPhysicalDeviceRayTracingInvocationReorderPropertiesNV VkPhysicalDeviceRayTracingInvocationReorderPropertiesNV;
    typedef struct VkPhysicalDeviceExtendedSparseAddressSpaceFeaturesNV VkPhysicalDeviceExtendedSparseAddressSpaceFeaturesNV;
    typedef struct VkPhysicalDeviceExtendedSparseAddressSpacePropertiesNV VkPhysicalDeviceExtendedSparseAddressSpacePropertiesNV;
    typedef struct VkDirectDriverLoadingInfoLUNARG VkDirectDriverLoadingInfoLUNARG;
    typedef struct VkDirectDriverLoadingListLUNARG VkDirectDriverLoadingListLUNARG;
    typedef struct VkPhysicalDeviceMultiviewPerViewViewportsFeaturesQCOM VkPhysicalDeviceMultiviewPerViewViewportsFeaturesQCOM;
    typedef struct VkPhysicalDeviceRayTracingPositionFetchFeaturesKHR VkPhysicalDeviceRayTracingPositionFetchFeaturesKHR;
    typedef struct VkDeviceImageSubresourceInfo VkDeviceImageSubresourceInfo;
    typedef struct VkDeviceImageSubresourceInfoKHR VkDeviceImageSubresourceInfoKHR;
    typedef struct VkPhysicalDeviceShaderCorePropertiesARM VkPhysicalDeviceShaderCorePropertiesARM;
    typedef struct VkPhysicalDeviceMultiviewPerViewRenderAreasFeaturesQCOM VkPhysicalDeviceMultiviewPerViewRenderAreasFeaturesQCOM;
    typedef struct VkMultiviewPerViewRenderAreasRenderPassBeginInfoQCOM VkMultiviewPerViewRenderAreasRenderPassBeginInfoQCOM;
    typedef struct VkQueryLowLatencySupportNV VkQueryLowLatencySupportNV;
    typedef struct VkMemoryMapInfo VkMemoryMapInfo;
    typedef struct VkMemoryMapInfoKHR VkMemoryMapInfoKHR;
    typedef struct VkMemoryUnmapInfo VkMemoryUnmapInfo;
    typedef struct VkMemoryUnmapInfoKHR VkMemoryUnmapInfoKHR;
    typedef struct VkPhysicalDeviceShaderObjectFeaturesEXT VkPhysicalDeviceShaderObjectFeaturesEXT;
    typedef struct VkPhysicalDeviceShaderObjectPropertiesEXT VkPhysicalDeviceShaderObjectPropertiesEXT;
    typedef struct VkShaderCreateInfoEXT VkShaderCreateInfoEXT;
    typedef struct VkPhysicalDeviceShaderTileImageFeaturesEXT VkPhysicalDeviceShaderTileImageFeaturesEXT;
    typedef struct VkPhysicalDeviceShaderTileImagePropertiesEXT VkPhysicalDeviceShaderTileImagePropertiesEXT;
    typedef struct VkImportScreenBufferInfoQNX VkImportScreenBufferInfoQNX;
    typedef struct VkScreenBufferPropertiesQNX VkScreenBufferPropertiesQNX;
    typedef struct VkScreenBufferFormatPropertiesQNX VkScreenBufferFormatPropertiesQNX;
    typedef struct VkExternalFormatQNX VkExternalFormatQNX;
    typedef struct VkPhysicalDeviceExternalMemoryScreenBufferFeaturesQNX VkPhysicalDeviceExternalMemoryScreenBufferFeaturesQNX;
    typedef struct VkPhysicalDeviceCooperativeMatrixFeaturesKHR VkPhysicalDeviceCooperativeMatrixFeaturesKHR;
    typedef struct VkCooperativeMatrixPropertiesKHR VkCooperativeMatrixPropertiesKHR;
    typedef struct VkPhysicalDeviceCooperativeMatrixPropertiesKHR VkPhysicalDeviceCooperativeMatrixPropertiesKHR;
    typedef struct VkPhysicalDeviceCooperativeMatrixConversionFeaturesQCOM VkPhysicalDeviceCooperativeMatrixConversionFeaturesQCOM;
    typedef struct VkPhysicalDeviceShaderEnqueuePropertiesAMDX VkPhysicalDeviceShaderEnqueuePropertiesAMDX;
    typedef struct VkPhysicalDeviceShaderEnqueueFeaturesAMDX VkPhysicalDeviceShaderEnqueueFeaturesAMDX;
    typedef struct VkExecutionGraphPipelineCreateInfoAMDX VkExecutionGraphPipelineCreateInfoAMDX;
    typedef struct VkPipelineShaderStageNodeCreateInfoAMDX VkPipelineShaderStageNodeCreateInfoAMDX;
    typedef struct VkExecutionGraphPipelineScratchSizeAMDX VkExecutionGraphPipelineScratchSizeAMDX;
    typedef struct VkDispatchGraphInfoAMDX VkDispatchGraphInfoAMDX;
    typedef struct VkDispatchGraphCountInfoAMDX VkDispatchGraphCountInfoAMDX;
    typedef struct VkPhysicalDeviceAntiLagFeaturesAMD VkPhysicalDeviceAntiLagFeaturesAMD;
    typedef struct VkAntiLagDataAMD VkAntiLagDataAMD;
    typedef struct VkAntiLagPresentationInfoAMD VkAntiLagPresentationInfoAMD;
    typedef struct VkBindMemoryStatus VkBindMemoryStatus;
    typedef struct VkPhysicalDeviceTileMemoryHeapFeaturesQCOM VkPhysicalDeviceTileMemoryHeapFeaturesQCOM;
    typedef struct VkPhysicalDeviceTileMemoryHeapPropertiesQCOM VkPhysicalDeviceTileMemoryHeapPropertiesQCOM;
    typedef struct VkTileMemorySizeInfoQCOM VkTileMemorySizeInfoQCOM;
    typedef struct VkTileMemoryRequirementsQCOM VkTileMemoryRequirementsQCOM;
    typedef struct VkBindMemoryStatusKHR VkBindMemoryStatusKHR;
    typedef struct VkBindDescriptorSetsInfo VkBindDescriptorSetsInfo;
    typedef struct VkBindDescriptorSetsInfoKHR VkBindDescriptorSetsInfoKHR;
    typedef struct VkPushConstantsInfo VkPushConstantsInfo;
    typedef struct VkPushConstantsInfoKHR VkPushConstantsInfoKHR;
    typedef struct VkPushDescriptorSetInfo VkPushDescriptorSetInfo;
    typedef struct VkPushDescriptorSetInfoKHR VkPushDescriptorSetInfoKHR;
    typedef struct VkPushDescriptorSetWithTemplateInfo VkPushDescriptorSetWithTemplateInfo;
    typedef struct VkPushDescriptorSetWithTemplateInfoKHR VkPushDescriptorSetWithTemplateInfoKHR;
    typedef struct VkSetDescriptorBufferOffsetsInfoEXT VkSetDescriptorBufferOffsetsInfoEXT;
    typedef struct VkBindDescriptorBufferEmbeddedSamplersInfoEXT VkBindDescriptorBufferEmbeddedSamplersInfoEXT;
    typedef struct VkPhysicalDeviceCubicClampFeaturesQCOM VkPhysicalDeviceCubicClampFeaturesQCOM;
    typedef struct VkPhysicalDeviceYcbcrDegammaFeaturesQCOM VkPhysicalDeviceYcbcrDegammaFeaturesQCOM;
    typedef struct VkSamplerYcbcrConversionYcbcrDegammaCreateInfoQCOM VkSamplerYcbcrConversionYcbcrDegammaCreateInfoQCOM;
    typedef struct VkPhysicalDeviceCubicWeightsFeaturesQCOM VkPhysicalDeviceCubicWeightsFeaturesQCOM;
    typedef struct VkSamplerCubicWeightsCreateInfoQCOM VkSamplerCubicWeightsCreateInfoQCOM;
    typedef struct VkBlitImageCubicWeightsInfoQCOM VkBlitImageCubicWeightsInfoQCOM;
    typedef struct VkPhysicalDeviceImageProcessing2FeaturesQCOM VkPhysicalDeviceImageProcessing2FeaturesQCOM;
    typedef struct VkPhysicalDeviceImageProcessing2PropertiesQCOM VkPhysicalDeviceImageProcessing2PropertiesQCOM;
    typedef struct VkSamplerBlockMatchWindowCreateInfoQCOM VkSamplerBlockMatchWindowCreateInfoQCOM;
    typedef struct VkPhysicalDeviceDescriptorPoolOverallocationFeaturesNV VkPhysicalDeviceDescriptorPoolOverallocationFeaturesNV;
    typedef struct VkPhysicalDeviceLayeredDriverPropertiesMSFT VkPhysicalDeviceLayeredDriverPropertiesMSFT;
    typedef struct VkPhysicalDevicePerStageDescriptorSetFeaturesNV VkPhysicalDevicePerStageDescriptorSetFeaturesNV;
    typedef struct VkPhysicalDeviceExternalFormatResolveFeaturesANDROID VkPhysicalDeviceExternalFormatResolveFeaturesANDROID;
    typedef struct VkPhysicalDeviceExternalFormatResolvePropertiesANDROID VkPhysicalDeviceExternalFormatResolvePropertiesANDROID;
    typedef struct VkAndroidHardwareBufferFormatResolvePropertiesANDROID VkAndroidHardwareBufferFormatResolvePropertiesANDROID;
    typedef struct VkLatencySleepModeInfoNV VkLatencySleepModeInfoNV;
    typedef struct VkLatencySleepInfoNV VkLatencySleepInfoNV;
    typedef struct VkSetLatencyMarkerInfoNV VkSetLatencyMarkerInfoNV;
    typedef struct VkGetLatencyMarkerInfoNV VkGetLatencyMarkerInfoNV;
    typedef struct VkLatencyTimingsFrameReportNV VkLatencyTimingsFrameReportNV;
    typedef struct VkOutOfBandQueueTypeInfoNV VkOutOfBandQueueTypeInfoNV;
    typedef struct VkLatencySubmissionPresentIdNV VkLatencySubmissionPresentIdNV;
    typedef struct VkSwapchainLatencyCreateInfoNV VkSwapchainLatencyCreateInfoNV;
    typedef struct VkLatencySurfaceCapabilitiesNV VkLatencySurfaceCapabilitiesNV;
    typedef struct VkPhysicalDeviceCudaKernelLaunchFeaturesNV VkPhysicalDeviceCudaKernelLaunchFeaturesNV;
    typedef struct VkPhysicalDeviceCudaKernelLaunchPropertiesNV VkPhysicalDeviceCudaKernelLaunchPropertiesNV;
    typedef struct VkDeviceQueueShaderCoreControlCreateInfoARM VkDeviceQueueShaderCoreControlCreateInfoARM;
    typedef struct VkPhysicalDeviceSchedulingControlsFeaturesARM VkPhysicalDeviceSchedulingControlsFeaturesARM;
    typedef struct VkPhysicalDeviceSchedulingControlsPropertiesARM VkPhysicalDeviceSchedulingControlsPropertiesARM;
    typedef struct VkPhysicalDeviceRelaxedLineRasterizationFeaturesIMG VkPhysicalDeviceRelaxedLineRasterizationFeaturesIMG;
    typedef struct VkPhysicalDeviceRenderPassStripedFeaturesARM VkPhysicalDeviceRenderPassStripedFeaturesARM;
    typedef struct VkPhysicalDeviceRenderPassStripedPropertiesARM VkPhysicalDeviceRenderPassStripedPropertiesARM;
    typedef struct VkRenderPassStripeInfoARM VkRenderPassStripeInfoARM;
    typedef struct VkRenderPassStripeBeginInfoARM VkRenderPassStripeBeginInfoARM;
    typedef struct VkRenderPassStripeSubmitInfoARM VkRenderPassStripeSubmitInfoARM;
    typedef struct VkPhysicalDevicePipelineOpacityMicromapFeaturesARM VkPhysicalDevicePipelineOpacityMicromapFeaturesARM;
    typedef struct VkPhysicalDeviceShaderMaximalReconvergenceFeaturesKHR VkPhysicalDeviceShaderMaximalReconvergenceFeaturesKHR;
    typedef struct VkPhysicalDeviceShaderSubgroupRotateFeatures VkPhysicalDeviceShaderSubgroupRotateFeatures;
    typedef struct VkPhysicalDeviceShaderSubgroupRotateFeaturesKHR VkPhysicalDeviceShaderSubgroupRotateFeaturesKHR;
    typedef struct VkPhysicalDeviceShaderExpectAssumeFeatures VkPhysicalDeviceShaderExpectAssumeFeatures;
    typedef struct VkPhysicalDeviceShaderExpectAssumeFeaturesKHR VkPhysicalDeviceShaderExpectAssumeFeaturesKHR;
    typedef struct VkPhysicalDeviceShaderFloatControls2Features VkPhysicalDeviceShaderFloatControls2Features;
    typedef struct VkPhysicalDeviceShaderFloatControls2FeaturesKHR VkPhysicalDeviceShaderFloatControls2FeaturesKHR;
    typedef struct VkPhysicalDeviceDynamicRenderingLocalReadFeatures VkPhysicalDeviceDynamicRenderingLocalReadFeatures;
    typedef struct VkPhysicalDeviceDynamicRenderingLocalReadFeaturesKHR VkPhysicalDeviceDynamicRenderingLocalReadFeaturesKHR;
    typedef struct VkRenderingAttachmentLocationInfo VkRenderingAttachmentLocationInfo;
    typedef struct VkRenderingAttachmentLocationInfoKHR VkRenderingAttachmentLocationInfoKHR;
    typedef struct VkRenderingInputAttachmentIndexInfo VkRenderingInputAttachmentIndexInfo;
    typedef struct VkRenderingInputAttachmentIndexInfoKHR VkRenderingInputAttachmentIndexInfoKHR;
    typedef struct VkPhysicalDeviceShaderQuadControlFeaturesKHR VkPhysicalDeviceShaderQuadControlFeaturesKHR;
    typedef struct VkPhysicalDeviceShaderAtomicFloat16VectorFeaturesNV VkPhysicalDeviceShaderAtomicFloat16VectorFeaturesNV;
    typedef struct VkPhysicalDeviceMapMemoryPlacedFeaturesEXT VkPhysicalDeviceMapMemoryPlacedFeaturesEXT;
    typedef struct VkPhysicalDeviceMapMemoryPlacedPropertiesEXT VkPhysicalDeviceMapMemoryPlacedPropertiesEXT;
    typedef struct VkMemoryMapPlacedInfoEXT VkMemoryMapPlacedInfoEXT;
    typedef struct VkPhysicalDeviceShaderBfloat16FeaturesKHR VkPhysicalDeviceShaderBfloat16FeaturesKHR;
    typedef struct VkPhysicalDeviceRawAccessChainsFeaturesNV VkPhysicalDeviceRawAccessChainsFeaturesNV;
    typedef struct VkPhysicalDeviceCommandBufferInheritanceFeaturesNV VkPhysicalDeviceCommandBufferInheritanceFeaturesNV;
    typedef struct VkPhysicalDeviceImageAlignmentControlFeaturesMESA VkPhysicalDeviceImageAlignmentControlFeaturesMESA;
    typedef struct VkPhysicalDeviceImageAlignmentControlPropertiesMESA VkPhysicalDeviceImageAlignmentControlPropertiesMESA;
    typedef struct VkImageAlignmentControlCreateInfoMESA VkImageAlignmentControlCreateInfoMESA;
    typedef struct VkPhysicalDeviceShaderReplicatedCompositesFeaturesEXT VkPhysicalDeviceShaderReplicatedCompositesFeaturesEXT;
    typedef struct VkPhysicalDevicePresentModeFifoLatestReadyFeaturesEXT VkPhysicalDevicePresentModeFifoLatestReadyFeaturesEXT;
    typedef struct VkPhysicalDevicePresentModeFifoLatestReadyFeaturesKHR VkPhysicalDevicePresentModeFifoLatestReadyFeaturesKHR;
    typedef struct VkDepthClampRangeEXT VkDepthClampRangeEXT;
    typedef struct VkPhysicalDeviceCooperativeMatrix2FeaturesNV VkPhysicalDeviceCooperativeMatrix2FeaturesNV;
    typedef struct VkPhysicalDeviceCooperativeMatrix2PropertiesNV VkPhysicalDeviceCooperativeMatrix2PropertiesNV;
    typedef struct VkCooperativeMatrixFlexibleDimensionsPropertiesNV VkCooperativeMatrixFlexibleDimensionsPropertiesNV;
    typedef struct VkPhysicalDeviceHdrVividFeaturesHUAWEI VkPhysicalDeviceHdrVividFeaturesHUAWEI;
    typedef struct VkPhysicalDeviceVertexAttributeRobustnessFeaturesEXT VkPhysicalDeviceVertexAttributeRobustnessFeaturesEXT;
    typedef struct VkPhysicalDeviceDenseGeometryFormatFeaturesAMDX VkPhysicalDeviceDenseGeometryFormatFeaturesAMDX;
    typedef struct VkAccelerationStructureDenseGeometryFormatTrianglesDataAMDX VkAccelerationStructureDenseGeometryFormatTrianglesDataAMDX;
    typedef struct VkPhysicalDeviceDepthClampZeroOneFeaturesKHR VkPhysicalDeviceDepthClampZeroOneFeaturesKHR;
    typedef struct VkPhysicalDeviceCooperativeVectorFeaturesNV VkPhysicalDeviceCooperativeVectorFeaturesNV;
    typedef struct VkCooperativeVectorPropertiesNV VkCooperativeVectorPropertiesNV;
    typedef struct VkPhysicalDeviceCooperativeVectorPropertiesNV VkPhysicalDeviceCooperativeVectorPropertiesNV;
    typedef struct VkConvertCooperativeVectorMatrixInfoNV VkConvertCooperativeVectorMatrixInfoNV;
    typedef struct VkPhysicalDeviceTileShadingFeaturesQCOM VkPhysicalDeviceTileShadingFeaturesQCOM;
    typedef struct VkPhysicalDeviceTileShadingPropertiesQCOM VkPhysicalDeviceTileShadingPropertiesQCOM;
    typedef struct VkRenderPassTileShadingCreateInfoQCOM VkRenderPassTileShadingCreateInfoQCOM;
    typedef struct VkPerTileBeginInfoQCOM VkPerTileBeginInfoQCOM;
    typedef struct VkPerTileEndInfoQCOM VkPerTileEndInfoQCOM;
    typedef struct VkDispatchTileInfoQCOM VkDispatchTileInfoQCOM;
    typedef struct VkPhysicalDeviceFragmentDensityMapLayeredPropertiesVALVE VkPhysicalDeviceFragmentDensityMapLayeredPropertiesVALVE;
    typedef struct VkPhysicalDeviceFragmentDensityMapLayeredFeaturesVALVE VkPhysicalDeviceFragmentDensityMapLayeredFeaturesVALVE;
    typedef struct VkPipelineFragmentDensityMapLayeredCreateInfoVALVE VkPipelineFragmentDensityMapLayeredCreateInfoVALVE;
    typedef struct VkSetPresentConfigNV VkSetPresentConfigNV;
    typedef struct VkPhysicalDevicePresentMeteringFeaturesNV VkPhysicalDevicePresentMeteringFeaturesNV;
    typedef struct VkExternalComputeQueueDeviceCreateInfoNV VkExternalComputeQueueDeviceCreateInfoNV;
    typedef struct VkExternalComputeQueueCreateInfoNV VkExternalComputeQueueCreateInfoNV;
    typedef struct VkExternalComputeQueueDataParamsNV VkExternalComputeQueueDataParamsNV;
    typedef struct VkPhysicalDeviceExternalComputeQueuePropertiesNV VkPhysicalDeviceExternalComputeQueuePropertiesNV;
    typedef struct VkExternalComputeQueueNV_T* VkExternalComputeQueueNV;
    typedef struct VkPhysicalDeviceShaderUniformBufferUnsizedArrayFeaturesEXT VkPhysicalDeviceShaderUniformBufferUnsizedArrayFeaturesEXT;
    typedef struct VkPhysicalDeviceFormatPackFeaturesARM VkPhysicalDeviceFormatPackFeaturesARM;
    typedef struct VkTensorDescriptionARM VkTensorDescriptionARM;
    typedef struct VkTensorCreateInfoARM VkTensorCreateInfoARM;
    typedef struct VkTensorViewCreateInfoARM VkTensorViewCreateInfoARM;
    typedef struct VkTensorMemoryRequirementsInfoARM VkTensorMemoryRequirementsInfoARM;
    typedef struct VkBindTensorMemoryInfoARM VkBindTensorMemoryInfoARM;
    typedef struct VkWriteDescriptorSetTensorARM VkWriteDescriptorSetTensorARM;
    typedef struct VkTensorFormatPropertiesARM VkTensorFormatPropertiesARM;
    typedef struct VkPhysicalDeviceTensorPropertiesARM VkPhysicalDeviceTensorPropertiesARM;
    typedef struct VkTensorMemoryBarrierARM VkTensorMemoryBarrierARM;
    typedef struct VkTensorDependencyInfoARM VkTensorDependencyInfoARM;
    typedef struct VkPhysicalDeviceTensorFeaturesARM VkPhysicalDeviceTensorFeaturesARM;
    typedef struct VkDeviceTensorMemoryRequirementsARM VkDeviceTensorMemoryRequirementsARM;
    typedef struct VkCopyTensorInfoARM VkCopyTensorInfoARM;
    typedef struct VkTensorCopyARM VkTensorCopyARM;
    typedef struct VkMemoryDedicatedAllocateInfoTensorARM VkMemoryDedicatedAllocateInfoTensorARM;
    typedef struct VkPhysicalDeviceDescriptorBufferTensorPropertiesARM VkPhysicalDeviceDescriptorBufferTensorPropertiesARM;
    typedef struct VkPhysicalDeviceDescriptorBufferTensorFeaturesARM VkPhysicalDeviceDescriptorBufferTensorFeaturesARM;
    typedef struct VkTensorCaptureDescriptorDataInfoARM VkTensorCaptureDescriptorDataInfoARM;
    typedef struct VkTensorViewCaptureDescriptorDataInfoARM VkTensorViewCaptureDescriptorDataInfoARM;
    typedef struct VkDescriptorGetTensorInfoARM VkDescriptorGetTensorInfoARM;
    typedef struct VkFrameBoundaryTensorsARM VkFrameBoundaryTensorsARM;
    typedef struct VkPhysicalDeviceExternalTensorInfoARM VkPhysicalDeviceExternalTensorInfoARM;
    typedef struct VkExternalTensorPropertiesARM VkExternalTensorPropertiesARM;
    typedef struct VkExternalMemoryTensorCreateInfoARM VkExternalMemoryTensorCreateInfoARM;
    typedef struct VkPhysicalDeviceShaderFloat8FeaturesEXT VkPhysicalDeviceShaderFloat8FeaturesEXT;
    typedef struct VkSurfaceCreateInfoOHOS VkSurfaceCreateInfoOHOS;
    typedef struct VkPhysicalDeviceDataGraphFeaturesARM VkPhysicalDeviceDataGraphFeaturesARM;
    typedef struct VkDataGraphPipelineConstantTensorSemiStructuredSparsityInfoARM VkDataGraphPipelineConstantTensorSemiStructuredSparsityInfoARM;
    typedef struct VkDataGraphPipelineConstantARM VkDataGraphPipelineConstantARM;
    typedef struct VkDataGraphPipelineResourceInfoARM VkDataGraphPipelineResourceInfoARM;
    typedef struct VkDataGraphPipelineCompilerControlCreateInfoARM VkDataGraphPipelineCompilerControlCreateInfoARM;
    typedef struct VkDataGraphPipelineCreateInfoARM VkDataGraphPipelineCreateInfoARM;
    typedef struct VkDataGraphPipelineShaderModuleCreateInfoARM VkDataGraphPipelineShaderModuleCreateInfoARM;
    typedef struct VkDataGraphPipelineSessionCreateInfoARM VkDataGraphPipelineSessionCreateInfoARM;
    typedef struct VkDataGraphPipelineSessionBindPointRequirementsInfoARM VkDataGraphPipelineSessionBindPointRequirementsInfoARM;
    typedef struct VkDataGraphPipelineSessionBindPointRequirementARM VkDataGraphPipelineSessionBindPointRequirementARM;
    typedef struct VkDataGraphPipelineSessionMemoryRequirementsInfoARM VkDataGraphPipelineSessionMemoryRequirementsInfoARM;
    typedef struct VkBindDataGraphPipelineSessionMemoryInfoARM VkBindDataGraphPipelineSessionMemoryInfoARM;
    typedef struct VkDataGraphPipelineInfoARM VkDataGraphPipelineInfoARM;
    typedef struct VkDataGraphPipelinePropertyQueryResultARM VkDataGraphPipelinePropertyQueryResultARM;
    typedef struct VkDataGraphPipelineIdentifierCreateInfoARM VkDataGraphPipelineIdentifierCreateInfoARM;
    typedef struct VkDataGraphPipelineDispatchInfoARM VkDataGraphPipelineDispatchInfoARM;
    typedef struct VkPhysicalDeviceDataGraphProcessingEngineARM VkPhysicalDeviceDataGraphProcessingEngineARM;
    typedef struct VkPhysicalDeviceDataGraphOperationSupportARM VkPhysicalDeviceDataGraphOperationSupportARM;
    typedef struct VkQueueFamilyDataGraphPropertiesARM VkQueueFamilyDataGraphPropertiesARM;
    typedef struct VkPhysicalDeviceQueueFamilyDataGraphProcessingEngineInfoARM VkPhysicalDeviceQueueFamilyDataGraphProcessingEngineInfoARM;
    typedef struct VkQueueFamilyDataGraphProcessingEnginePropertiesARM VkQueueFamilyDataGraphProcessingEnginePropertiesARM;
    typedef struct VkDataGraphProcessingEngineCreateInfoARM VkDataGraphProcessingEngineCreateInfoARM;
    typedef struct VkPhysicalDevicePipelineCacheIncrementalModeFeaturesSEC VkPhysicalDevicePipelineCacheIncrementalModeFeaturesSEC;
    typedef struct VkDataGraphPipelineBuiltinModelCreateInfoQCOM VkDataGraphPipelineBuiltinModelCreateInfoQCOM;
    typedef struct VkPhysicalDeviceDataGraphModelFeaturesQCOM VkPhysicalDeviceDataGraphModelFeaturesQCOM;
    typedef struct VkPhysicalDeviceShaderUntypedPointersFeaturesKHR VkPhysicalDeviceShaderUntypedPointersFeaturesKHR;
    typedef struct VkNativeBufferOHOS VkNativeBufferOHOS;
    typedef struct VkSwapchainImageCreateInfoOHOS VkSwapchainImageCreateInfoOHOS;
    typedef struct VkPhysicalDevicePresentationPropertiesOHOS VkPhysicalDevicePresentationPropertiesOHOS;
    typedef struct VkPhysicalDeviceVideoEncodeRgbConversionFeaturesVALVE VkPhysicalDeviceVideoEncodeRgbConversionFeaturesVALVE;
    typedef struct VkVideoEncodeRgbConversionCapabilitiesVALVE VkVideoEncodeRgbConversionCapabilitiesVALVE;
    typedef struct VkVideoEncodeProfileRgbConversionInfoVALVE VkVideoEncodeProfileRgbConversionInfoVALVE;
    typedef struct VkVideoEncodeSessionRgbConversionCreateInfoVALVE VkVideoEncodeSessionRgbConversionCreateInfoVALVE;
    typedef struct VkPhysicalDeviceShader64BitIndexingFeaturesEXT VkPhysicalDeviceShader64BitIndexingFeaturesEXT;
    typedef struct VkNativeBufferUsageOHOS VkNativeBufferUsageOHOS;
    typedef struct VkNativeBufferPropertiesOHOS VkNativeBufferPropertiesOHOS;
    typedef struct VkNativeBufferFormatPropertiesOHOS VkNativeBufferFormatPropertiesOHOS;
    typedef struct VkImportNativeBufferInfoOHOS VkImportNativeBufferInfoOHOS;
    typedef struct VkMemoryGetNativeBufferInfoOHOS VkMemoryGetNativeBufferInfoOHOS;
    typedef struct VkExternalFormatOHOS VkExternalFormatOHOS;
    typedef struct VkPhysicalDevicePerformanceCountersByRegionFeaturesARM VkPhysicalDevicePerformanceCountersByRegionFeaturesARM;
    typedef struct VkPhysicalDevicePerformanceCountersByRegionPropertiesARM VkPhysicalDevicePerformanceCountersByRegionPropertiesARM;
    typedef struct VkPerformanceCounterARM VkPerformanceCounterARM;
    typedef struct VkPerformanceCounterDescriptionARM VkPerformanceCounterDescriptionARM;
    typedef struct VkRenderPassPerformanceCountersByRegionBeginInfoARM VkRenderPassPerformanceCountersByRegionBeginInfoARM;
    typedef struct VkComputeOccupancyPriorityParametersNV VkComputeOccupancyPriorityParametersNV;
    typedef struct VkPhysicalDeviceComputeOccupancyPriorityFeaturesNV VkPhysicalDeviceComputeOccupancyPriorityFeaturesNV;
    typedef struct VkPhysicalDeviceShaderLongVectorFeaturesEXT VkPhysicalDeviceShaderLongVectorFeaturesEXT;
    typedef struct VkPhysicalDeviceShaderLongVectorPropertiesEXT VkPhysicalDeviceShaderLongVectorPropertiesEXT;
    typedef struct VkPhysicalDeviceTextureCompressionASTC3DFeaturesEXT VkPhysicalDeviceTextureCompressionASTC3DFeaturesEXT;
    typedef struct VkPhysicalDeviceShaderSubgroupPartitionedFeaturesEXT VkPhysicalDeviceShaderSubgroupPartitionedFeaturesEXT;
    typedef struct VkHostAddressRangeEXT VkHostAddressRangeEXT;
    typedef struct VkHostAddressRangeConstEXT VkHostAddressRangeConstEXT;
    typedef struct VkDeviceAddressRangeEXT VkDeviceAddressRangeEXT;
    typedef struct VkTexelBufferDescriptorInfoEXT VkTexelBufferDescriptorInfoEXT;
    typedef struct VkImageDescriptorInfoEXT VkImageDescriptorInfoEXT;
    typedef union VkResourceDescriptorDataEXT VkResourceDescriptorDataEXT;
    typedef struct VkResourceDescriptorInfoEXT VkResourceDescriptorInfoEXT;
    typedef struct VkBindHeapInfoEXT VkBindHeapInfoEXT;
    typedef struct VkPushDataInfoEXT VkPushDataInfoEXT;
    typedef struct VkDescriptorMappingSourceConstantOffsetEXT VkDescriptorMappingSourceConstantOffsetEXT;
    typedef struct VkDescriptorMappingSourcePushIndexEXT VkDescriptorMappingSourcePushIndexEXT;
    typedef struct VkDescriptorMappingSourceIndirectIndexEXT VkDescriptorMappingSourceIndirectIndexEXT;
    typedef struct VkDescriptorMappingSourceIndirectIndexArrayEXT VkDescriptorMappingSourceIndirectIndexArrayEXT;
    typedef struct VkDescriptorMappingSourceHeapDataEXT VkDescriptorMappingSourceHeapDataEXT;
    typedef struct VkDescriptorMappingSourceShaderRecordIndexEXT VkDescriptorMappingSourceShaderRecordIndexEXT;
    typedef struct VkDescriptorMappingSourceIndirectAddressEXT VkDescriptorMappingSourceIndirectAddressEXT;
    typedef union VkDescriptorMappingSourceDataEXT VkDescriptorMappingSourceDataEXT;
    typedef struct VkDescriptorSetAndBindingMappingEXT VkDescriptorSetAndBindingMappingEXT;
    typedef struct VkShaderDescriptorSetAndBindingMappingInfoEXT VkShaderDescriptorSetAndBindingMappingInfoEXT;
    typedef struct VkSamplerCustomBorderColorIndexCreateInfoEXT VkSamplerCustomBorderColorIndexCreateInfoEXT;
    typedef struct VkOpaqueCaptureDataCreateInfoEXT VkOpaqueCaptureDataCreateInfoEXT;
    typedef struct VkIndirectCommandsLayoutPushDataTokenNV VkIndirectCommandsLayoutPushDataTokenNV;
    typedef struct VkSubsampledImageFormatPropertiesEXT VkSubsampledImageFormatPropertiesEXT;
    typedef struct VkPhysicalDeviceDescriptorHeapFeaturesEXT VkPhysicalDeviceDescriptorHeapFeaturesEXT;
    typedef struct VkPhysicalDeviceDescriptorHeapPropertiesEXT VkPhysicalDeviceDescriptorHeapPropertiesEXT;
    typedef struct VkCommandBufferInheritanceDescriptorHeapInfoEXT VkCommandBufferInheritanceDescriptorHeapInfoEXT;
    typedef struct VkPhysicalDeviceDescriptorHeapTensorPropertiesARM VkPhysicalDeviceDescriptorHeapTensorPropertiesARM;
    typedef void (*PFN_vkInternalAllocationNotification)(void*                       pUserData, size_t                      size, VkInternalAllocationType    allocationType, VkSystemAllocationScope     allocationScope);
    typedef void (*PFN_vkInternalFreeNotification)(void*                       pUserData, size_t                      size, VkInternalAllocationType    allocationType, VkSystemAllocationScope     allocationScope);
    typedef void* (*PFN_vkReallocationFunction)(void*                       pUserData, void*                       pOriginal, size_t                      size, size_t                      alignment, VkSystemAllocationScope     allocationScope);
    typedef void* (*PFN_vkAllocationFunction)(void*                       pUserData, size_t                      size, size_t                      alignment, VkSystemAllocationScope     allocationScope);
    typedef void (*PFN_vkFreeFunction)(void*                       pUserData, void*                       pMemory);
    typedef void (*PFN_vkVoidFunction)();
    typedef VkBool32 (*PFN_vkDebugReportCallbackEXT)(VkDebugReportFlagsEXT       flags, VkDebugReportObjectTypeEXT  objectType, uint64_t                    object, size_t                      location, int32_t                     messageCode, const char*                 pLayerPrefix, const char*                 pMessage, void*                       pUserData);
    typedef VkBool32 (*PFN_vkDebugUtilsMessengerCallbackEXT)(VkDebugUtilsMessageSeverityFlagBitsEXT      messageSeverity, VkDebugUtilsMessageTypeFlagsEXT             messageTypes, const VkDebugUtilsMessengerCallbackDataEXT* pCallbackData, void*                                       pUserData);
    typedef void (*PFN_vkFaultCallbackFunction)(VkBool32                    unrecordedFaults, uint32_t                    faultCount, const VkFaultData*          pFaults);
    typedef void (*PFN_vkDeviceMemoryReportCallbackEXT)(const VkDeviceMemoryReportCallbackDataEXT*  pCallbackData, void*                                       pUserData);
    typedef PFN_vkVoidFunction (*PFN_vkGetInstanceProcAddrLUNARG)(VkInstance                  instance, const char*                 pName);
    typedef void* AHardwareBuffer;
    typedef void* ANativeWindow;
    typedef void* CAMetalLayer;
    typedef void* DWORD;
    typedef void* Display;
    typedef void* GgpFrameToken;
    typedef void* GgpStreamDescriptor;
    typedef void* HANDLE;
    typedef void* HINSTANCE;
    typedef void* HMONITOR;
    typedef void* HWND;
    typedef void* IDirectFB;
    typedef void* IDirectFBSurface;
    typedef void* IOSurfaceRef;
    typedef void* LPCWSTR;
    typedef void* MTLBuffer_id;
    typedef void* MTLCommandQueue_id;
    typedef void* MTLDevice_id;
    typedef void* MTLSharedEvent_id;
    typedef void* MTLTexture_id;
    typedef void* NvSciBufAttrList;
    typedef void* NvSciBufObj;
    typedef void* NvSciSyncAttrList;
    typedef void* NvSciSyncFence;
    typedef void* NvSciSyncObj;
    typedef void* OHBufferHandle;
    typedef void* OHNativeWindow;
    typedef void* OH_NativeBuffer;
    typedef void* RROutput;
    typedef void* SECURITY_ATTRIBUTES;
    typedef void* StdVideoAV1Level;
    typedef void* StdVideoAV1Profile;
    typedef void* StdVideoAV1SequenceHeader;
    typedef void* StdVideoDecodeAV1PictureInfo;
    typedef void* StdVideoDecodeAV1ReferenceInfo;
    typedef void* StdVideoDecodeH264PictureInfo;
    typedef void* StdVideoDecodeH264ReferenceInfo;
    typedef void* StdVideoDecodeH265PictureInfo;
    typedef void* StdVideoDecodeH265ReferenceInfo;
    typedef void* StdVideoDecodeVP9PictureInfo;
    typedef void* StdVideoEncodeAV1DecoderModelInfo;
    typedef void* StdVideoEncodeAV1OperatingPointInfo;
    typedef void* StdVideoEncodeAV1PictureInfo;
    typedef void* StdVideoEncodeAV1ReferenceInfo;
    typedef void* StdVideoEncodeH264PictureInfo;
    typedef void* StdVideoEncodeH264ReferenceInfo;
    typedef void* StdVideoEncodeH264SliceHeader;
    typedef void* StdVideoEncodeH265PictureInfo;
    typedef void* StdVideoEncodeH265ReferenceInfo;
    typedef void* StdVideoEncodeH265SliceSegmentHeader;
    typedef void* StdVideoH264LevelIdc;
    typedef void* StdVideoH264PictureParameterSet;
    typedef void* StdVideoH264ProfileIdc;
    typedef void* StdVideoH264SequenceParameterSet;
    typedef void* StdVideoH265LevelIdc;
    typedef void* StdVideoH265PictureParameterSet;
    typedef void* StdVideoH265ProfileIdc;
    typedef void* StdVideoH265SequenceParameterSet;
    typedef void* StdVideoH265VideoParameterSet;
    typedef void* StdVideoVP9Level;
    typedef void* StdVideoVP9Profile;
    typedef void* VisualID;
    typedef void* Window;
    typedef void* _screen_buffer;
    typedef void* _screen_context;
    typedef void* _screen_window;
    typedef void* ubm_device;
    typedef void* ubm_surface;
    typedef void* wl_display;
    typedef void* wl_surface;
    typedef void* xcb_connection_t;
    typedef void* xcb_visualid_t;
    typedef void* xcb_window_t;
    typedef void* zx_handle_t;

    struct VkBaseOutStructure { VkStructureType sType; struct VkBaseOutStructure* pNext; };
    struct VkBaseInStructure { VkStructureType sType; struct VkBaseInStructure* pNext; };
    struct VkOffset2D {
        int32_t x;
        int32_t y;
    };

    struct VkOffset3D {
        int32_t x;
        int32_t y;
        int32_t z;
    };

    struct VkExtent2D {
        uint32_t width;
        uint32_t height;
    };

    struct VkExtent3D {
        uint32_t width;
        uint32_t height;
        uint32_t depth;
    };

    struct VkViewport {
        float x;
        float y;
        float width;
        float height;
        float minDepth;
        float maxDepth;
    };

    struct VkRect2D {
        VkOffset2D offset;
        VkExtent2D extent;
    };

    struct VkClearRect {
        VkRect2D rect;
        uint32_t baseArrayLayer;
        uint32_t layerCount;
    };

    struct VkComponentMapping {
        VkComponentSwizzle r;
        VkComponentSwizzle g;
        VkComponentSwizzle b;
        VkComponentSwizzle a;
    };

    struct VkPhysicalDeviceSparseProperties {
        VkBool32 residencyStandard2DBlockShape;
        VkBool32 residencyStandard2DMultisampleBlockShape;
        VkBool32 residencyStandard3DBlockShape;
        VkBool32 residencyAlignedMipSize;
        VkBool32 residencyNonResidentStrict;
    };

    struct VkPhysicalDeviceLimits {
        uint32_t maxImageDimension1D;
        uint32_t maxImageDimension2D;
        uint32_t maxImageDimension3D;
        uint32_t maxImageDimensionCube;
        uint32_t maxImageArrayLayers;
        uint32_t maxTexelBufferElements;
        uint32_t maxUniformBufferRange;
        uint32_t maxStorageBufferRange;
        uint32_t maxPushConstantsSize;
        uint32_t maxMemoryAllocationCount;
        uint32_t maxSamplerAllocationCount;
        VkDeviceSize bufferImageGranularity;
        VkDeviceSize sparseAddressSpaceSize;
        uint32_t maxBoundDescriptorSets;
        uint32_t maxPerStageDescriptorSamplers;
        uint32_t maxPerStageDescriptorUniformBuffers;
        uint32_t maxPerStageDescriptorStorageBuffers;
        uint32_t maxPerStageDescriptorSampledImages;
        uint32_t maxPerStageDescriptorStorageImages;
        uint32_t maxPerStageDescriptorInputAttachments;
        uint32_t maxPerStageResources;
        uint32_t maxDescriptorSetSamplers;
        uint32_t maxDescriptorSetUniformBuffers;
        uint32_t maxDescriptorSetUniformBuffersDynamic;
        uint32_t maxDescriptorSetStorageBuffers;
        uint32_t maxDescriptorSetStorageBuffersDynamic;
        uint32_t maxDescriptorSetSampledImages;
        uint32_t maxDescriptorSetStorageImages;
        uint32_t maxDescriptorSetInputAttachments;
        uint32_t maxVertexInputAttributes;
        uint32_t maxVertexInputBindings;
        uint32_t maxVertexInputAttributeOffset;
        uint32_t maxVertexInputBindingStride;
        uint32_t maxVertexOutputComponents;
        uint32_t maxTessellationGenerationLevel;
        uint32_t maxTessellationPatchSize;
        uint32_t maxTessellationControlPerVertexInputComponents;
        uint32_t maxTessellationControlPerVertexOutputComponents;
        uint32_t maxTessellationControlPerPatchOutputComponents;
        uint32_t maxTessellationControlTotalOutputComponents;
        uint32_t maxTessellationEvaluationInputComponents;
        uint32_t maxTessellationEvaluationOutputComponents;
        uint32_t maxGeometryShaderInvocations;
        uint32_t maxGeometryInputComponents;
        uint32_t maxGeometryOutputComponents;
        uint32_t maxGeometryOutputVertices;
        uint32_t maxGeometryTotalOutputComponents;
        uint32_t maxFragmentInputComponents;
        uint32_t maxFragmentOutputAttachments;
        uint32_t maxFragmentDualSrcAttachments;
        uint32_t maxFragmentCombinedOutputResources;
        uint32_t maxComputeSharedMemorySize;
        uint32_t maxComputeWorkGroupCount[3];
        uint32_t maxComputeWorkGroupInvocations;
        uint32_t maxComputeWorkGroupSize[3];
        uint32_t subPixelPrecisionBits;
        uint32_t subTexelPrecisionBits;
        uint32_t mipmapPrecisionBits;
        uint32_t maxDrawIndexedIndexValue;
        uint32_t maxDrawIndirectCount;
        float maxSamplerLodBias;
        float maxSamplerAnisotropy;
        uint32_t maxViewports;
        uint32_t maxViewportDimensions[2];
        float viewportBoundsRange[2];
        uint32_t viewportSubPixelBits;
        size_t minMemoryMapAlignment;
        VkDeviceSize minTexelBufferOffsetAlignment;
        VkDeviceSize minUniformBufferOffsetAlignment;
        VkDeviceSize minStorageBufferOffsetAlignment;
        int32_t minTexelOffset;
        uint32_t maxTexelOffset;
        int32_t minTexelGatherOffset;
        uint32_t maxTexelGatherOffset;
        float minInterpolationOffset;
        float maxInterpolationOffset;
        uint32_t subPixelInterpolationOffsetBits;
        uint32_t maxFramebufferWidth;
        uint32_t maxFramebufferHeight;
        uint32_t maxFramebufferLayers;
        VkSampleCountFlags framebufferColorSampleCounts;
        VkSampleCountFlags framebufferDepthSampleCounts;
        VkSampleCountFlags framebufferStencilSampleCounts;
        VkSampleCountFlags framebufferNoAttachmentsSampleCounts;
        uint32_t maxColorAttachments;
        VkSampleCountFlags sampledImageColorSampleCounts;
        VkSampleCountFlags sampledImageIntegerSampleCounts;
        VkSampleCountFlags sampledImageDepthSampleCounts;
        VkSampleCountFlags sampledImageStencilSampleCounts;
        VkSampleCountFlags storageImageSampleCounts;
        uint32_t maxSampleMaskWords;
        VkBool32 timestampComputeAndGraphics;
        float timestampPeriod;
        uint32_t maxClipDistances;
        uint32_t maxCullDistances;
        uint32_t maxCombinedClipAndCullDistances;
        uint32_t discreteQueuePriorities;
        float pointSizeRange[2];
        float lineWidthRange[2];
        float pointSizeGranularity;
        float lineWidthGranularity;
        VkBool32 strictLines;
        VkBool32 standardSampleLocations;
        VkDeviceSize optimalBufferCopyOffsetAlignment;
        VkDeviceSize optimalBufferCopyRowPitchAlignment;
        VkDeviceSize nonCoherentAtomSize;
    };

    struct VkPhysicalDeviceProperties {
        uint32_t apiVersion;
        uint32_t driverVersion;
        uint32_t vendorID;
        uint32_t deviceID;
        VkPhysicalDeviceType deviceType;
        char deviceName[256];
        uint8_t pipelineCacheUUID[16];
        VkPhysicalDeviceLimits limits;
        VkPhysicalDeviceSparseProperties sparseProperties;
    };

    struct VkExtensionProperties {
        char extensionName[256];
        uint32_t specVersion;
    };

    struct VkLayerProperties {
        char layerName[256];
        uint32_t specVersion;
        uint32_t implementationVersion;
        char description[256];
    };

    struct VkApplicationInfo {
        VkStructureType sType;
        const void* pNext;
        const char* pApplicationName;
        uint32_t applicationVersion;
        const char* pEngineName;
        uint32_t engineVersion;
        uint32_t apiVersion;
    };

    struct VkAllocationCallbacks {
        void* pUserData;
        PFN_vkAllocationFunction pfnAllocation;
        PFN_vkReallocationFunction pfnReallocation;
        PFN_vkFreeFunction pfnFree;
        PFN_vkInternalAllocationNotification pfnInternalAllocation;
        PFN_vkInternalFreeNotification pfnInternalFree;
    };

    struct VkDeviceQueueCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkDeviceQueueCreateFlags flags;
        uint32_t queueFamilyIndex;
        uint32_t queueCount;
        const float* pQueuePriorities;
    };

    struct VkDeviceCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkDeviceCreateFlags flags;
        uint32_t queueCreateInfoCount;
        const VkDeviceQueueCreateInfo* pQueueCreateInfos;
        uint32_t enabledLayerCount;
        const char* const* ppEnabledLayerNames;
        uint32_t enabledExtensionCount;
        const char* const* ppEnabledExtensionNames;
        const VkPhysicalDeviceFeatures* pEnabledFeatures;
    };

    struct VkInstanceCreateInfo {
        VkStructureType sType;
        void* pNext;
        VkInstanceCreateFlags flags;
        VkApplicationInfo* pApplicationInfo;
        uint32_t enabledLayerCount;
        char** ppEnabledLayerNames;
        uint32_t enabledExtensionCount;
        char** ppEnabledExtensionNames;
    };

    struct VkQueueFamilyProperties {
        VkQueueFlags queueFlags;
        uint32_t queueCount;
        uint32_t timestampValidBits;
        VkExtent3D minImageTransferGranularity;
    };

    struct VkMemoryType {
        VkMemoryPropertyFlags propertyFlags;
        uint32_t heapIndex;
    };

    struct VkMemoryHeap {
        VkDeviceSize size;
        VkMemoryHeapFlags flags;
    };

    struct VkPhysicalDeviceMemoryProperties {
        uint32_t memoryTypeCount;
        VkMemoryType memoryTypes[32];
        uint32_t memoryHeapCount;
        VkMemoryHeap memoryHeaps[16];
    };

    struct VkMemoryAllocateInfo {
        VkStructureType sType;
        const void* pNext;
        VkDeviceSize allocationSize;
        uint32_t memoryTypeIndex;
    };

    struct VkMemoryRequirements {
        VkDeviceSize size;
        VkDeviceSize alignment;
        uint32_t memoryTypeBits;
    };

    struct VkSparseImageFormatProperties {
        VkImageAspectFlags aspectMask;
        VkExtent3D imageGranularity;
        VkSparseImageFormatFlags flags;
    };

    struct VkSparseImageMemoryRequirements {
        VkSparseImageFormatProperties formatProperties;
        uint32_t imageMipTailFirstLod;
        VkDeviceSize imageMipTailSize;
        VkDeviceSize imageMipTailOffset;
        VkDeviceSize imageMipTailStride;
    };

    struct VkMappedMemoryRange {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
        VkDeviceSize offset;
        VkDeviceSize size;
    };

    struct VkFormatProperties {
        VkFormatFeatureFlags linearTilingFeatures;
        VkFormatFeatureFlags optimalTilingFeatures;
        VkFormatFeatureFlags bufferFeatures;
    };

    struct VkImageFormatProperties {
        VkExtent3D maxExtent;
        uint32_t maxMipLevels;
        uint32_t maxArrayLayers;
        VkSampleCountFlags sampleCounts;
        VkDeviceSize maxResourceSize;
    };

    struct VkDescriptorBufferInfo {
        VkBuffer buffer;
        VkDeviceSize offset;
        VkDeviceSize range;
    };

    struct VkDescriptorImageInfo {
        VkSampler sampler;
        VkImageView imageView;
        VkImageLayout imageLayout;
    };

    struct VkWriteDescriptorSet {
        VkStructureType sType;
        const void* pNext;
        VkDescriptorSet dstSet;
        uint32_t dstBinding;
        uint32_t dstArrayElement;
        uint32_t descriptorCount;
        VkDescriptorType descriptorType;
        const VkDescriptorImageInfo* pImageInfo;
        const VkDescriptorBufferInfo* pBufferInfo;
        const VkBufferView* pTexelBufferView;
    };

    struct VkCopyDescriptorSet {
        VkStructureType sType;
        const void* pNext;
        VkDescriptorSet srcSet;
        uint32_t srcBinding;
        uint32_t srcArrayElement;
        VkDescriptorSet dstSet;
        uint32_t dstBinding;
        uint32_t dstArrayElement;
        uint32_t descriptorCount;
    };

    struct VkBufferUsageFlags2CreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkBufferUsageFlags2 usage;
    };

    struct VkBufferUsageFlags2CreateInfoKHR {
    };

    struct VkBufferCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkBufferCreateFlags flags;
        VkDeviceSize size;
        VkBufferUsageFlags usage;
        VkSharingMode sharingMode;
        uint32_t queueFamilyIndexCount;
        const uint32_t* pQueueFamilyIndices;
    };

    struct VkBufferViewCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkBufferViewCreateFlags flags;
        VkBuffer buffer;
        VkFormat format;
        VkDeviceSize offset;
        VkDeviceSize range;
    };

    struct VkImageSubresource {
        VkImageAspectFlags aspectMask;
        uint32_t mipLevel;
        uint32_t arrayLayer;
    };

    struct VkImageSubresourceLayers {
        VkImageAspectFlags aspectMask;
        uint32_t mipLevel;
        uint32_t baseArrayLayer;
        uint32_t layerCount;
    };

    struct VkImageSubresourceRange {
        VkImageAspectFlags aspectMask;
        uint32_t baseMipLevel;
        uint32_t levelCount;
        uint32_t baseArrayLayer;
        uint32_t layerCount;
    };

    struct VkMemoryBarrier {
        VkStructureType sType;
        const void* pNext;
        VkAccessFlags srcAccessMask;
        VkAccessFlags dstAccessMask;
    };

    struct VkBufferMemoryBarrier {
        VkStructureType sType;
        const void* pNext;
        VkAccessFlags srcAccessMask;
        VkAccessFlags dstAccessMask;
        uint32_t srcQueueFamilyIndex;
        uint32_t dstQueueFamilyIndex;
        VkBuffer buffer;
        VkDeviceSize offset;
        VkDeviceSize size;
    };

    struct VkImageMemoryBarrier {
        VkStructureType sType;
        const void* pNext;
        VkAccessFlags srcAccessMask;
        VkAccessFlags dstAccessMask;
        VkImageLayout oldLayout;
        VkImageLayout newLayout;
        uint32_t srcQueueFamilyIndex;
        uint32_t dstQueueFamilyIndex;
        VkImage image;
        VkImageSubresourceRange subresourceRange;
    };

    struct VkImageCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkImageCreateFlags flags;
        VkImageType imageType;
        VkFormat format;
        VkExtent3D extent;
        uint32_t mipLevels;
        uint32_t arrayLayers;
        VkSampleCountFlagBits samples;
        VkImageTiling tiling;
        VkImageUsageFlags usage;
        VkSharingMode sharingMode;
        uint32_t queueFamilyIndexCount;
        const uint32_t* pQueueFamilyIndices;
        VkImageLayout initialLayout;
    };

    struct VkSubresourceLayout {
        VkDeviceSize offset;
        VkDeviceSize size;
        VkDeviceSize rowPitch;
        VkDeviceSize arrayPitch;
        VkDeviceSize depthPitch;
    };

    struct VkImageViewCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkImageViewCreateFlags flags;
        VkImage image;
        VkImageViewType viewType;
        VkFormat format;
        VkComponentMapping components;
        VkImageSubresourceRange subresourceRange;
    };

    struct VkBufferCopy {
        VkDeviceSize srcOffset;
        VkDeviceSize dstOffset;
        VkDeviceSize size;
    };

    struct VkSparseMemoryBind {
        VkDeviceSize resourceOffset;
        VkDeviceSize size;
        VkDeviceMemory memory;
        VkDeviceSize memoryOffset;
        VkSparseMemoryBindFlags flags;
    };

    struct VkSparseImageMemoryBind {
        VkImageSubresource subresource;
        VkOffset3D offset;
        VkExtent3D extent;
        VkDeviceMemory memory;
        VkDeviceSize memoryOffset;
        VkSparseMemoryBindFlags flags;
    };

    struct VkSparseBufferMemoryBindInfo {
        VkBuffer buffer;
        uint32_t bindCount;
        const VkSparseMemoryBind* pBinds;
    };

    struct VkSparseImageOpaqueMemoryBindInfo {
        VkImage image;
        uint32_t bindCount;
        const VkSparseMemoryBind* pBinds;
    };

    struct VkSparseImageMemoryBindInfo {
        VkImage image;
        uint32_t bindCount;
        const VkSparseImageMemoryBind* pBinds;
    };

    struct VkBindSparseInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t waitSemaphoreCount;
        const VkSemaphore* pWaitSemaphores;
        uint32_t bufferBindCount;
        const VkSparseBufferMemoryBindInfo* pBufferBinds;
        uint32_t imageOpaqueBindCount;
        const VkSparseImageOpaqueMemoryBindInfo* pImageOpaqueBinds;
        uint32_t imageBindCount;
        const VkSparseImageMemoryBindInfo* pImageBinds;
        uint32_t signalSemaphoreCount;
        const VkSemaphore* pSignalSemaphores;
    };

    struct VkImageCopy {
        VkImageSubresourceLayers srcSubresource;
        VkOffset3D srcOffset;
        VkImageSubresourceLayers dstSubresource;
        VkOffset3D dstOffset;
        VkExtent3D extent;
    };

    struct VkImageBlit {
        VkImageSubresourceLayers srcSubresource;
        VkOffset3D srcOffsets[2];
        VkImageSubresourceLayers dstSubresource;
        VkOffset3D dstOffsets[2];
    };

    struct VkBufferImageCopy {
        VkDeviceSize bufferOffset;
        uint32_t bufferRowLength;
        uint32_t bufferImageHeight;
        VkImageSubresourceLayers imageSubresource;
        VkOffset3D imageOffset;
        VkExtent3D imageExtent;
    };

    struct VkStridedDeviceAddressRangeKHR {
        VkDeviceAddress address;
        VkDeviceSize size;
        VkDeviceSize stride;
    };

    struct VkCopyMemoryIndirectCommandKHR {
        VkDeviceAddress srcAddress;
        VkDeviceAddress dstAddress;
        VkDeviceSize size;
    };

    struct VkCopyMemoryIndirectCommandNV {
    };

    struct VkCopyMemoryIndirectInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkAddressCopyFlagsKHR srcCopyFlags;
        VkAddressCopyFlagsKHR dstCopyFlags;
        uint32_t copyCount;
        VkStridedDeviceAddressRangeKHR copyAddressRange;
    };

    struct VkCopyMemoryToImageIndirectCommandKHR {
        VkDeviceAddress srcAddress;
        uint32_t bufferRowLength;
        uint32_t bufferImageHeight;
        VkImageSubresourceLayers imageSubresource;
        VkOffset3D imageOffset;
        VkExtent3D imageExtent;
    };

    struct VkCopyMemoryToImageIndirectCommandNV {
    };

    struct VkCopyMemoryToImageIndirectInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkAddressCopyFlagsKHR srcCopyFlags;
        uint32_t copyCount;
        VkStridedDeviceAddressRangeKHR copyAddressRange;
        VkImage dstImage;
        VkImageLayout dstImageLayout;
        const VkImageSubresourceLayers* pImageSubresources;
    };

    struct VkImageResolve {
        VkImageSubresourceLayers srcSubresource;
        VkOffset3D srcOffset;
        VkImageSubresourceLayers dstSubresource;
        VkOffset3D dstOffset;
        VkExtent3D extent;
    };

    struct VkShaderModuleCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkShaderModuleCreateFlags flags;
        size_t codeSize;
        const uint32_t* pCode;
    };

    struct VkDescriptorSetLayoutBinding {
        uint32_t binding;
        VkDescriptorType descriptorType;
        uint32_t descriptorCount;
        VkShaderStageFlags stageFlags;
        const VkSampler* pImmutableSamplers;
    };

    struct VkDescriptorSetLayoutCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkDescriptorSetLayoutCreateFlags flags;
        uint32_t bindingCount;
        const VkDescriptorSetLayoutBinding* pBindings;
    };

    struct VkDescriptorPoolSize {
        VkDescriptorType type;
        uint32_t descriptorCount;
    };

    struct VkDescriptorPoolCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkDescriptorPoolCreateFlags flags;
        uint32_t maxSets;
        uint32_t poolSizeCount;
        const VkDescriptorPoolSize* pPoolSizes;
    };

    struct VkDescriptorSetAllocateInfo {
        VkStructureType sType;
        const void* pNext;
        VkDescriptorPool descriptorPool;
        uint32_t descriptorSetCount;
        const VkDescriptorSetLayout* pSetLayouts;
    };

    struct VkSpecializationMapEntry {
        uint32_t constantID;
        uint32_t offset;
        size_t size;
    };

    struct VkSpecializationInfo {
        uint32_t mapEntryCount;
        const VkSpecializationMapEntry* pMapEntries;
        size_t dataSize;
        const void* pData;
    };

    struct VkPipelineShaderStageCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineShaderStageCreateFlags flags;
        VkShaderStageFlagBits stage;
        VkShaderModule module;
        const char* pName;
        const VkSpecializationInfo* pSpecializationInfo;
    };

    struct VkComputePipelineCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCreateFlags flags;
        VkPipelineShaderStageCreateInfo stage;
        VkPipelineLayout layout;
        VkPipeline basePipelineHandle;
        int32_t basePipelineIndex;
    };

    struct VkComputePipelineIndirectBufferInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkDeviceAddress deviceAddress;
        VkDeviceSize size;
        VkDeviceAddress pipelineDeviceAddressCaptureReplay;
    };

    struct VkPipelineCreateFlags2CreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCreateFlags2 flags;
    };

    struct VkPipelineCreateFlags2CreateInfoKHR {
    };

    struct VkVertexInputBindingDescription {
        uint32_t binding;
        uint32_t stride;
        VkVertexInputRate inputRate;
    };

    struct VkVertexInputAttributeDescription {
        uint32_t location;
        uint32_t binding;
        VkFormat format;
        uint32_t offset;
    };

    struct VkPipelineVertexInputStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineVertexInputStateCreateFlags flags;
        uint32_t vertexBindingDescriptionCount;
        const VkVertexInputBindingDescription* pVertexBindingDescriptions;
        uint32_t vertexAttributeDescriptionCount;
        const VkVertexInputAttributeDescription* pVertexAttributeDescriptions;
    };

    struct VkPipelineInputAssemblyStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineInputAssemblyStateCreateFlags flags;
        VkPrimitiveTopology topology;
        VkBool32 primitiveRestartEnable;
    };

    struct VkPipelineTessellationStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineTessellationStateCreateFlags flags;
        uint32_t patchControlPoints;
    };

    struct VkPipelineViewportStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineViewportStateCreateFlags flags;
        uint32_t viewportCount;
        const VkViewport* pViewports;
        uint32_t scissorCount;
        const VkRect2D* pScissors;
    };

    struct VkPipelineRasterizationStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineRasterizationStateCreateFlags flags;
        VkBool32 depthClampEnable;
        VkBool32 rasterizerDiscardEnable;
        VkPolygonMode polygonMode;
        VkCullModeFlags cullMode;
        VkFrontFace frontFace;
        VkBool32 depthBiasEnable;
        float depthBiasConstantFactor;
        float depthBiasClamp;
        float depthBiasSlopeFactor;
        float lineWidth;
    };

    struct VkPipelineMultisampleStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineMultisampleStateCreateFlags flags;
        VkSampleCountFlagBits rasterizationSamples;
        VkBool32 sampleShadingEnable;
        float minSampleShading;
        const VkSampleMask* pSampleMask;
        VkBool32 alphaToCoverageEnable;
        VkBool32 alphaToOneEnable;
    };

    struct VkPipelineColorBlendAttachmentState {
        VkBool32 blendEnable;
        VkBlendFactor srcColorBlendFactor;
        VkBlendFactor dstColorBlendFactor;
        VkBlendOp colorBlendOp;
        VkBlendFactor srcAlphaBlendFactor;
        VkBlendFactor dstAlphaBlendFactor;
        VkBlendOp alphaBlendOp;
        VkColorComponentFlags colorWriteMask;
    };

    struct VkPipelineColorBlendStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineColorBlendStateCreateFlags flags;
        VkBool32 logicOpEnable;
        VkLogicOp logicOp;
        uint32_t attachmentCount;
        const VkPipelineColorBlendAttachmentState* pAttachments;
        float blendConstants[4];
    };

    struct VkPipelineDynamicStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineDynamicStateCreateFlags flags;
        uint32_t dynamicStateCount;
        const VkDynamicState* pDynamicStates;
    };

    struct VkStencilOpState {
        VkStencilOp failOp;
        VkStencilOp passOp;
        VkStencilOp depthFailOp;
        VkCompareOp compareOp;
        uint32_t compareMask;
        uint32_t writeMask;
        uint32_t reference;
    };

    struct VkPipelineDepthStencilStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineDepthStencilStateCreateFlags flags;
        VkBool32 depthTestEnable;
        VkBool32 depthWriteEnable;
        VkCompareOp depthCompareOp;
        VkBool32 depthBoundsTestEnable;
        VkBool32 stencilTestEnable;
        VkStencilOpState front;
        VkStencilOpState back;
        float minDepthBounds;
        float maxDepthBounds;
    };

    struct VkGraphicsPipelineCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCreateFlags flags;
        uint32_t stageCount;
        const VkPipelineShaderStageCreateInfo* pStages;
        const VkPipelineVertexInputStateCreateInfo* pVertexInputState;
        const VkPipelineInputAssemblyStateCreateInfo* pInputAssemblyState;
        const VkPipelineTessellationStateCreateInfo* pTessellationState;
        const VkPipelineViewportStateCreateInfo* pViewportState;
        const VkPipelineRasterizationStateCreateInfo* pRasterizationState;
        const VkPipelineMultisampleStateCreateInfo* pMultisampleState;
        const VkPipelineDepthStencilStateCreateInfo* pDepthStencilState;
        const VkPipelineColorBlendStateCreateInfo* pColorBlendState;
        const VkPipelineDynamicStateCreateInfo* pDynamicState;
        VkPipelineLayout layout;
        VkRenderPass renderPass;
        uint32_t subpass;
        VkPipeline basePipelineHandle;
        int32_t basePipelineIndex;
    };

    struct VkPipelineCacheCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCacheCreateFlags flags;
        size_t initialDataSize;
        const void* pInitialData;
    };

    struct VkPipelineCacheHeaderVersionOne {
        uint32_t headerSize;
        VkPipelineCacheHeaderVersion headerVersion;
        uint32_t vendorID;
        uint32_t deviceID;
        uint8_t pipelineCacheUUID[16];
    };

    struct VkPipelineCacheStageValidationIndexEntry {
        uint64_t codeSize;
        uint64_t codeOffset;
    };

    struct VkPipelineCacheSafetyCriticalIndexEntry {
        uint8_t pipelineIdentifier[16];
        uint64_t pipelineMemorySize;
        uint64_t jsonSize;
        uint64_t jsonOffset;
        uint32_t stageIndexCount;
        uint32_t stageIndexStride;
        uint64_t stageIndexOffset;
    };

    struct VkPipelineCacheHeaderVersionSafetyCriticalOne {
        VkPipelineCacheHeaderVersionOne headerVersionOne;
        VkPipelineCacheValidationVersion validationVersion;
        uint32_t implementationData;
        uint32_t pipelineIndexCount;
        uint32_t pipelineIndexStride;
        uint64_t pipelineIndexOffset;
    };

    struct VkPipelineCacheHeaderVersionDataGraphQCOM {
        uint32_t headerSize;
        VkPipelineCacheHeaderVersion headerVersion;
        VkDataGraphModelCacheTypeQCOM cacheType;
        uint32_t cacheVersion;
        uint32_t toolchainVersion[3];
    };

    struct VkPushConstantRange {
        VkShaderStageFlags stageFlags;
        uint32_t offset;
        uint32_t size;
    };

    struct VkPipelineBinaryCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const VkPipelineBinaryKeysAndDataKHR* pKeysAndDataInfo;
        VkPipeline pipeline;
        const VkPipelineCreateInfoKHR* pPipelineCreateInfo;
    };

    struct VkPipelineBinaryHandlesInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t pipelineBinaryCount;
        VkPipelineBinaryKHR* pPipelineBinaries;
    };

    struct VkPipelineBinaryDataKHR {
        size_t dataSize;
        void* pData;
    };

    struct VkPipelineBinaryKeysAndDataKHR {
        uint32_t binaryCount;
        const VkPipelineBinaryKeyKHR* pPipelineBinaryKeys;
        const VkPipelineBinaryDataKHR* pPipelineBinaryData;
    };

    struct VkPipelineBinaryKeyKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t keySize;
        uint8_t key[32];
    };

    struct VkPipelineBinaryInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t binaryCount;
        const VkPipelineBinaryKHR* pPipelineBinaries;
    };

    struct VkReleaseCapturedPipelineDataInfoKHR {
        VkStructureType sType;
        void* pNext;
        VkPipeline pipeline;
    };

    struct VkPipelineBinaryDataInfoKHR {
        VkStructureType sType;
        void* pNext;
        VkPipelineBinaryKHR pipelineBinary;
    };

    struct VkPipelineCreateInfoKHR {
        VkStructureType sType;
        void* pNext;
    };

    struct VkPipelineLayoutCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineLayoutCreateFlags flags;
        uint32_t setLayoutCount;
        const VkDescriptorSetLayout* pSetLayouts;
        uint32_t pushConstantRangeCount;
        const VkPushConstantRange* pPushConstantRanges;
    };

    struct VkSamplerCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkSamplerCreateFlags flags;
        VkFilter magFilter;
        VkFilter minFilter;
        VkSamplerMipmapMode mipmapMode;
        VkSamplerAddressMode addressModeU;
        VkSamplerAddressMode addressModeV;
        VkSamplerAddressMode addressModeW;
        float mipLodBias;
        VkBool32 anisotropyEnable;
        float maxAnisotropy;
        VkBool32 compareEnable;
        VkCompareOp compareOp;
        float minLod;
        float maxLod;
        VkBorderColor borderColor;
        VkBool32 unnormalizedCoordinates;
    };

    struct VkCommandPoolCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkCommandPoolCreateFlags flags;
        uint32_t queueFamilyIndex;
    };

    struct VkCommandBufferAllocateInfo {
        VkStructureType sType;
        const void* pNext;
        VkCommandPool commandPool;
        VkCommandBufferLevel level;
        uint32_t commandBufferCount;
    };

    struct VkCommandBufferInheritanceInfo {
        VkStructureType sType;
        const void* pNext;
        VkRenderPass renderPass;
        uint32_t subpass;
        VkFramebuffer framebuffer;
        VkBool32 occlusionQueryEnable;
        VkQueryControlFlags queryFlags;
        VkQueryPipelineStatisticFlags pipelineStatistics;
    };

    struct VkCommandBufferBeginInfo {
        VkStructureType sType;
        const void* pNext;
        VkCommandBufferUsageFlags flags;
        const VkCommandBufferInheritanceInfo* pInheritanceInfo;
    };

    struct VkRenderPassBeginInfo {
        VkStructureType sType;
        const void* pNext;
        VkRenderPass renderPass;
        VkFramebuffer framebuffer;
        VkRect2D renderArea;
        uint32_t clearValueCount;
        const VkClearValue* pClearValues;
    };

    union VkClearColorValue {
        float float32[4];
        int32_t int32[4];
        uint32_t uint32[4];
    };

    struct VkClearDepthStencilValue {
        float depth;
        uint32_t stencil;
    };

    union VkClearValue {
        VkClearColorValue color;
        VkClearDepthStencilValue depthStencil;
    };

    struct VkClearAttachment {
        VkImageAspectFlags aspectMask;
        uint32_t colorAttachment;
        VkClearValue clearValue;
    };

    struct VkAttachmentDescription {
        VkAttachmentDescriptionFlags flags;
        VkFormat format;
        VkSampleCountFlagBits samples;
        VkAttachmentLoadOp loadOp;
        VkAttachmentStoreOp storeOp;
        VkAttachmentLoadOp stencilLoadOp;
        VkAttachmentStoreOp stencilStoreOp;
        VkImageLayout initialLayout;
        VkImageLayout finalLayout;
    };

    struct VkAttachmentReference {
        uint32_t attachment;
        VkImageLayout layout;
    };

    struct VkSubpassDescription {
        VkSubpassDescriptionFlags flags;
        VkPipelineBindPoint pipelineBindPoint;
        uint32_t inputAttachmentCount;
        const VkAttachmentReference* pInputAttachments;
        uint32_t colorAttachmentCount;
        const VkAttachmentReference* pColorAttachments;
        const VkAttachmentReference* pResolveAttachments;
        const VkAttachmentReference* pDepthStencilAttachment;
        uint32_t preserveAttachmentCount;
        const uint32_t* pPreserveAttachments;
    };

    struct VkSubpassDependency {
        uint32_t srcSubpass;
        uint32_t dstSubpass;
        VkPipelineStageFlags srcStageMask;
        VkPipelineStageFlags dstStageMask;
        VkAccessFlags srcAccessMask;
        VkAccessFlags dstAccessMask;
        VkDependencyFlags dependencyFlags;
    };

    struct VkRenderPassCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkRenderPassCreateFlags flags;
        uint32_t attachmentCount;
        const VkAttachmentDescription* pAttachments;
        uint32_t subpassCount;
        const VkSubpassDescription* pSubpasses;
        uint32_t dependencyCount;
        const VkSubpassDependency* pDependencies;
    };

    struct VkEventCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkEventCreateFlags flags;
    };

    struct VkFenceCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkFenceCreateFlags flags;
    };

    struct VkPhysicalDeviceFeatures {
        VkBool32 robustBufferAccess;
        VkBool32 fullDrawIndexUint32;
        VkBool32 imageCubeArray;
        VkBool32 independentBlend;
        VkBool32 geometryShader;
        VkBool32 tessellationShader;
        VkBool32 sampleRateShading;
        VkBool32 dualSrcBlend;
        VkBool32 logicOp;
        VkBool32 multiDrawIndirect;
        VkBool32 drawIndirectFirstInstance;
        VkBool32 depthClamp;
        VkBool32 depthBiasClamp;
        VkBool32 fillModeNonSolid;
        VkBool32 depthBounds;
        VkBool32 wideLines;
        VkBool32 largePoints;
        VkBool32 alphaToOne;
        VkBool32 multiViewport;
        VkBool32 samplerAnisotropy;
        VkBool32 textureCompressionETC2;
        VkBool32 textureCompressionASTC_LDR;
        VkBool32 textureCompressionBC;
        VkBool32 occlusionQueryPrecise;
        VkBool32 pipelineStatisticsQuery;
        VkBool32 vertexPipelineStoresAndAtomics;
        VkBool32 fragmentStoresAndAtomics;
        VkBool32 shaderTessellationAndGeometryPointSize;
        VkBool32 shaderImageGatherExtended;
        VkBool32 shaderStorageImageExtendedFormats;
        VkBool32 shaderStorageImageMultisample;
        VkBool32 shaderStorageImageReadWithoutFormat;
        VkBool32 shaderStorageImageWriteWithoutFormat;
        VkBool32 shaderUniformBufferArrayDynamicIndexing;
        VkBool32 shaderSampledImageArrayDynamicIndexing;
        VkBool32 shaderStorageBufferArrayDynamicIndexing;
        VkBool32 shaderStorageImageArrayDynamicIndexing;
        VkBool32 shaderClipDistance;
        VkBool32 shaderCullDistance;
        VkBool32 shaderFloat64;
        VkBool32 shaderInt64;
        VkBool32 shaderInt16;
        VkBool32 shaderResourceResidency;
        VkBool32 shaderResourceMinLod;
        VkBool32 sparseBinding;
        VkBool32 sparseResidencyBuffer;
        VkBool32 sparseResidencyImage2D;
        VkBool32 sparseResidencyImage3D;
        VkBool32 sparseResidency2Samples;
        VkBool32 sparseResidency4Samples;
        VkBool32 sparseResidency8Samples;
        VkBool32 sparseResidency16Samples;
        VkBool32 sparseResidencyAliased;
        VkBool32 variableMultisampleRate;
        VkBool32 inheritedQueries;
    };

    struct VkSemaphoreCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkSemaphoreCreateFlags flags;
    };

    struct VkQueryPoolCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkQueryPoolCreateFlags flags;
        VkQueryType queryType;
        uint32_t queryCount;
        VkQueryPipelineStatisticFlags pipelineStatistics;
    };

    struct VkFramebufferCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkFramebufferCreateFlags flags;
        VkRenderPass renderPass;
        uint32_t attachmentCount;
        const VkImageView* pAttachments;
        uint32_t width;
        uint32_t height;
        uint32_t layers;
    };

    struct VkDrawIndirectCommand {
        uint32_t vertexCount;
        uint32_t instanceCount;
        uint32_t firstVertex;
        uint32_t firstInstance;
    };

    struct VkDrawIndexedIndirectCommand {
        uint32_t indexCount;
        uint32_t instanceCount;
        uint32_t firstIndex;
        int32_t vertexOffset;
        uint32_t firstInstance;
    };

    struct VkDispatchIndirectCommand {
        uint32_t x;
        uint32_t y;
        uint32_t z;
    };

    struct VkMultiDrawInfoEXT {
        uint32_t firstVertex;
        uint32_t vertexCount;
    };

    struct VkMultiDrawIndexedInfoEXT {
        uint32_t firstIndex;
        uint32_t indexCount;
        int32_t vertexOffset;
    };

    struct VkSubmitInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t waitSemaphoreCount;
        const VkSemaphore* pWaitSemaphores;
        const VkPipelineStageFlags* pWaitDstStageMask;
        uint32_t commandBufferCount;
        const VkCommandBuffer* pCommandBuffers;
        uint32_t signalSemaphoreCount;
        const VkSemaphore* pSignalSemaphores;
    };

    struct VkDisplayPropertiesKHR {
        VkDisplayKHR display;
        const char* displayName;
        VkExtent2D physicalDimensions;
        VkExtent2D physicalResolution;
        VkSurfaceTransformFlagsKHR supportedTransforms;
        VkBool32 planeReorderPossible;
        VkBool32 persistentContent;
    };

    struct VkDisplayPlanePropertiesKHR {
        VkDisplayKHR currentDisplay;
        uint32_t currentStackIndex;
    };

    struct VkDisplayModeParametersKHR {
        VkExtent2D visibleRegion;
        uint32_t refreshRate;
    };

    struct VkDisplayModePropertiesKHR {
        VkDisplayModeKHR displayMode;
        VkDisplayModeParametersKHR parameters;
    };

    struct VkDisplayModeCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkDisplayModeCreateFlagsKHR flags;
        VkDisplayModeParametersKHR parameters;
    };

    struct VkDisplayPlaneCapabilitiesKHR {
        VkDisplayPlaneAlphaFlagsKHR supportedAlpha;
        VkOffset2D minSrcPosition;
        VkOffset2D maxSrcPosition;
        VkExtent2D minSrcExtent;
        VkExtent2D maxSrcExtent;
        VkOffset2D minDstPosition;
        VkOffset2D maxDstPosition;
        VkExtent2D minDstExtent;
        VkExtent2D maxDstExtent;
    };

    struct VkDisplaySurfaceCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkDisplaySurfaceCreateFlagsKHR flags;
        VkDisplayModeKHR displayMode;
        uint32_t planeIndex;
        uint32_t planeStackIndex;
        VkSurfaceTransformFlagBitsKHR transform;
        float globalAlpha;
        VkDisplayPlaneAlphaFlagBitsKHR alphaMode;
        VkExtent2D imageExtent;
    };

    struct VkDisplaySurfaceStereoCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkDisplaySurfaceStereoTypeNV stereoType;
    };

    struct VkDisplayPresentInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkRect2D srcRect;
        VkRect2D dstRect;
        VkBool32 persistent;
    };

    struct VkSurfaceCapabilitiesKHR {
        uint32_t minImageCount;
        uint32_t maxImageCount;
        VkExtent2D currentExtent;
        VkExtent2D minImageExtent;
        VkExtent2D maxImageExtent;
        uint32_t maxImageArrayLayers;
        VkSurfaceTransformFlagsKHR supportedTransforms;
        VkSurfaceTransformFlagBitsKHR currentTransform;
        VkCompositeAlphaFlagsKHR supportedCompositeAlpha;
        VkImageUsageFlags supportedUsageFlags;
    };

    struct VkAndroidSurfaceCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkAndroidSurfaceCreateFlagsKHR flags;
        struct ANativeWindow* window;
    };

    struct VkViSurfaceCreateInfoNN {
        VkStructureType sType;
        const void* pNext;
        VkViSurfaceCreateFlagsNN flags;
        void* window;
    };

    struct VkWaylandSurfaceCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkWaylandSurfaceCreateFlagsKHR flags;
        struct wl_display* display;
        struct wl_surface* surface;
    };

    struct VkUbmSurfaceCreateInfoSEC {
        VkStructureType sType;
        const void* pNext;
        VkUbmSurfaceCreateFlagsSEC flags;
        struct ubm_device* ubm_device;
        struct ubm_surface* ubm_surface;
    };

    struct VkWin32SurfaceCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkWin32SurfaceCreateFlagsKHR flags;
        HINSTANCE hinstance;
        HWND hwnd;
    };

    struct VkXlibSurfaceCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkXlibSurfaceCreateFlagsKHR flags;
        Display* dpy;
        Window window;
    };

    struct VkXcbSurfaceCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkXcbSurfaceCreateFlagsKHR flags;
        xcb_connection_t* connection;
        xcb_window_t window;
    };

    struct VkDirectFBSurfaceCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDirectFBSurfaceCreateFlagsEXT flags;
        IDirectFB* dfb;
        IDirectFBSurface* surface;
    };

    struct VkImagePipeSurfaceCreateInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        VkImagePipeSurfaceCreateFlagsFUCHSIA flags;
        zx_handle_t imagePipeHandle;
    };

    struct VkStreamDescriptorSurfaceCreateInfoGGP {
        VkStructureType sType;
        const void* pNext;
        VkStreamDescriptorSurfaceCreateFlagsGGP flags;
        GgpStreamDescriptor streamDescriptor;
    };

    struct VkScreenSurfaceCreateInfoQNX {
        VkStructureType sType;
        const void* pNext;
        VkScreenSurfaceCreateFlagsQNX flags;
        struct _screen_context* context;
        struct _screen_window* window;
    };

    struct VkSurfaceFormatKHR {
        VkFormat format;
        VkColorSpaceKHR colorSpace;
    };

    struct VkSwapchainCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkSwapchainCreateFlagsKHR flags;
        VkSurfaceKHR surface;
        uint32_t minImageCount;
        VkFormat imageFormat;
        VkColorSpaceKHR imageColorSpace;
        VkExtent2D imageExtent;
        uint32_t imageArrayLayers;
        VkImageUsageFlags imageUsage;
        VkSharingMode imageSharingMode;
        uint32_t queueFamilyIndexCount;
        const uint32_t* pQueueFamilyIndices;
        VkSurfaceTransformFlagBitsKHR preTransform;
        VkCompositeAlphaFlagBitsKHR compositeAlpha;
        VkPresentModeKHR presentMode;
        VkBool32 clipped;
        VkSwapchainKHR oldSwapchain;
    };

    struct VkPresentInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t waitSemaphoreCount;
        const VkSemaphore* pWaitSemaphores;
        uint32_t swapchainCount;
        const VkSwapchainKHR* pSwapchains;
        const uint32_t* pImageIndices;
        VkResult* pResults;
    };

    struct VkDebugReportCallbackCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDebugReportFlagsEXT flags;
        PFN_vkDebugReportCallbackEXT pfnCallback;
        void* pUserData;
    };

    struct VkValidationFlagsEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t disabledValidationCheckCount;
        const VkValidationCheckEXT* pDisabledValidationChecks;
    };

    struct VkValidationFeaturesEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t enabledValidationFeatureCount;
        const VkValidationFeatureEnableEXT* pEnabledValidationFeatures;
        uint32_t disabledValidationFeatureCount;
        const VkValidationFeatureDisableEXT* pDisabledValidationFeatures;
    };

    struct VkLayerSettingsCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t settingCount;
        const VkLayerSettingEXT* pSettings;
    };

    struct VkLayerSettingEXT {
        const char* pLayerName;
        const char* pSettingName;
        VkLayerSettingTypeEXT type;
        uint32_t valueCount;
        const void* pValues;
    };

    struct VkApplicationParametersEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t vendorID;
        uint32_t deviceID;
        uint32_t key;
        uint64_t value;
    };

    struct VkPipelineRasterizationStateRasterizationOrderAMD {
        VkStructureType sType;
        const void* pNext;
        VkRasterizationOrderAMD rasterizationOrder;
    };

    struct VkDebugMarkerObjectNameInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDebugReportObjectTypeEXT objectType;
        uint64_t object;
        const char* pObjectName;
    };

    struct VkDebugMarkerObjectTagInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDebugReportObjectTypeEXT objectType;
        uint64_t object;
        uint64_t tagName;
        size_t tagSize;
        const void* pTag;
    };

    struct VkDebugMarkerMarkerInfoEXT {
        VkStructureType sType;
        const void* pNext;
        const char* pMarkerName;
        float color[4];
    };

    struct VkDedicatedAllocationImageCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkBool32 dedicatedAllocation;
    };

    struct VkDedicatedAllocationBufferCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkBool32 dedicatedAllocation;
    };

    struct VkDedicatedAllocationMemoryAllocateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkImage image;
        VkBuffer buffer;
    };

    struct VkExternalImageFormatPropertiesNV {
        VkImageFormatProperties imageFormatProperties;
        VkExternalMemoryFeatureFlagsNV externalMemoryFeatures;
        VkExternalMemoryHandleTypeFlagsNV exportFromImportedHandleTypes;
        VkExternalMemoryHandleTypeFlagsNV compatibleHandleTypes;
    };

    struct VkExternalMemoryImageCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlagsNV handleTypes;
    };

    struct VkExportMemoryAllocateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlagsNV handleTypes;
    };

    struct VkImportMemoryWin32HandleInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlagsNV handleType;
        HANDLE handle;
    };

    struct VkExportMemoryWin32HandleInfoNV {
        VkStructureType sType;
        const void* pNext;
        const SECURITY_ATTRIBUTES* pAttributes;
        DWORD dwAccess;
    };

    struct VkExportMemorySciBufInfoNV {
        VkStructureType sType;
        const void* pNext;
        NvSciBufAttrList pAttributes;
    };

    struct VkImportMemorySciBufInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlagBits handleType;
        NvSciBufObj handle;
    };

    struct VkMemoryGetSciBufInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
        VkExternalMemoryHandleTypeFlagBits handleType;
    };

    struct VkMemorySciBufPropertiesNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t memoryTypeBits;
    };

    struct VkPhysicalDeviceExternalMemorySciBufFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 sciBufImport;
        VkBool32 sciBufExport;
    };

    struct VkPhysicalDeviceExternalSciBufFeaturesNV {
    };

    struct VkWin32KeyedMutexAcquireReleaseInfoNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t acquireCount;
        const VkDeviceMemory* pAcquireSyncs;
        const uint64_t* pAcquireKeys;
        const uint32_t* pAcquireTimeoutMilliseconds;
        uint32_t releaseCount;
        const VkDeviceMemory* pReleaseSyncs;
        const uint64_t* pReleaseKeys;
    };

    struct VkPhysicalDeviceDeviceGeneratedCommandsFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 deviceGeneratedCommands;
    };

    struct VkPushConstantBankInfoNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t bank;
    };

    struct VkPhysicalDevicePushConstantBankFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 pushConstantBank;
    };

    struct VkPhysicalDevicePushConstantBankPropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t maxGraphicsPushConstantBanks;
        uint32_t maxComputePushConstantBanks;
        uint32_t maxGraphicsPushDataBanks;
        uint32_t maxComputePushDataBanks;
    };

    struct VkPhysicalDeviceDeviceGeneratedCommandsComputeFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 deviceGeneratedCompute;
        VkBool32 deviceGeneratedComputePipelines;
        VkBool32 deviceGeneratedComputeCaptureReplay;
    };

    struct VkDevicePrivateDataCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t privateDataSlotRequestCount;
    };

    struct VkDevicePrivateDataCreateInfoEXT {
    };

    struct VkPrivateDataSlotCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPrivateDataSlotCreateFlags flags;
    };

    struct VkPrivateDataSlotCreateInfoEXT {
    };

    struct VkPhysicalDevicePrivateDataFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 privateData;
    };

    struct VkPhysicalDevicePrivateDataFeaturesEXT {
    };

    struct VkPhysicalDeviceDeviceGeneratedCommandsPropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t maxGraphicsShaderGroupCount;
        uint32_t maxIndirectSequenceCount;
        uint32_t maxIndirectCommandsTokenCount;
        uint32_t maxIndirectCommandsStreamCount;
        uint32_t maxIndirectCommandsTokenOffset;
        uint32_t maxIndirectCommandsStreamStride;
        uint32_t minSequencesCountBufferOffsetAlignment;
        uint32_t minSequencesIndexBufferOffsetAlignment;
        uint32_t minIndirectCommandsBufferOffsetAlignment;
    };

    struct VkPhysicalDeviceClusterAccelerationStructureFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 clusterAccelerationStructure;
    };

    struct VkPhysicalDeviceClusterAccelerationStructurePropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t maxVerticesPerCluster;
        uint32_t maxTrianglesPerCluster;
        uint32_t clusterScratchByteAlignment;
        uint32_t clusterByteAlignment;
        uint32_t clusterTemplateByteAlignment;
        uint32_t clusterBottomLevelByteAlignment;
        uint32_t clusterTemplateBoundsByteAlignment;
        uint32_t maxClusterGeometryIndex;
    };

    struct VkStridedDeviceAddressNV {
        VkDeviceAddress startAddress;
        VkDeviceSize strideInBytes;
    };

    struct VkRayTracingPipelineClusterAccelerationStructureCreateInfoNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 allowClusterAccelerationStructure;
    };

    struct VkClusterAccelerationStructureGeometryIndexAndGeometryFlagsNV {
        uint32_t geometryIndex;
        uint32_t reserved;
        uint32_t geometryFlags;
    };

    struct VkClusterAccelerationStructureMoveObjectsInfoNV {
        VkDeviceAddress srcAccelerationStructure;
    };

    struct VkClusterAccelerationStructureBuildClustersBottomLevelInfoNV {
        uint32_t clusterReferencesCount;
        uint32_t clusterReferencesStride;
        VkDeviceAddress clusterReferences;
    };

    struct VkClusterAccelerationStructureGetTemplateIndicesInfoNV {
        VkDeviceAddress clusterTemplateAddress;
    };

    struct VkClusterAccelerationStructureBuildTriangleClusterInfoNV {
        uint32_t clusterID;
        VkClusterAccelerationStructureClusterFlagsNV clusterFlags;
        uint32_t triangleCount;
        uint32_t vertexCount;
        uint32_t positionTruncateBitCount;
        uint32_t indexType;
        uint32_t opacityMicromapIndexType;
        VkClusterAccelerationStructureGeometryIndexAndGeometryFlagsNV baseGeometryIndexAndGeometryFlags;
        uint16_t indexBufferStride;
        uint16_t vertexBufferStride;
        uint16_t geometryIndexAndFlagsBufferStride;
        uint16_t opacityMicromapIndexBufferStride;
        VkDeviceAddress indexBuffer;
        VkDeviceAddress vertexBuffer;
        VkDeviceAddress geometryIndexAndFlagsBuffer;
        VkDeviceAddress opacityMicromapArray;
        VkDeviceAddress opacityMicromapIndexBuffer;
    };

    struct VkClusterAccelerationStructureBuildTriangleClusterTemplateInfoNV {
        uint32_t clusterID;
        VkClusterAccelerationStructureClusterFlagsNV clusterFlags;
        uint32_t triangleCount;
        uint32_t vertexCount;
        uint32_t positionTruncateBitCount;
        uint32_t indexType;
        uint32_t opacityMicromapIndexType;
        VkClusterAccelerationStructureGeometryIndexAndGeometryFlagsNV baseGeometryIndexAndGeometryFlags;
        uint16_t indexBufferStride;
        uint16_t vertexBufferStride;
        uint16_t geometryIndexAndFlagsBufferStride;
        uint16_t opacityMicromapIndexBufferStride;
        VkDeviceAddress indexBuffer;
        VkDeviceAddress vertexBuffer;
        VkDeviceAddress geometryIndexAndFlagsBuffer;
        VkDeviceAddress opacityMicromapArray;
        VkDeviceAddress opacityMicromapIndexBuffer;
        VkDeviceAddress instantiationBoundingBoxLimit;
    };

    struct VkClusterAccelerationStructureInstantiateClusterInfoNV {
        uint32_t clusterIdOffset;
        uint32_t geometryIndexOffset;
        uint32_t reserved;
        VkDeviceAddress clusterTemplateAddress;
        VkStridedDeviceAddressNV vertexBuffer;
    };

    struct VkClusterAccelerationStructureClustersBottomLevelInputNV {
        VkStructureType sType;
        void* pNext;
        uint32_t maxTotalClusterCount;
        uint32_t maxClusterCountPerAccelerationStructure;
    };

    struct VkClusterAccelerationStructureTriangleClusterInputNV {
        VkStructureType sType;
        void* pNext;
        VkFormat vertexFormat;
        uint32_t maxGeometryIndexValue;
        uint32_t maxClusterUniqueGeometryCount;
        uint32_t maxClusterTriangleCount;
        uint32_t maxClusterVertexCount;
        uint32_t maxTotalTriangleCount;
        uint32_t maxTotalVertexCount;
        uint32_t minPositionTruncateBitCount;
    };

    struct VkClusterAccelerationStructureMoveObjectsInputNV {
        VkStructureType sType;
        void* pNext;
        VkClusterAccelerationStructureTypeNV type;
        VkBool32 noMoveOverlap;
        VkDeviceSize maxMovedBytes;
    };

    union VkClusterAccelerationStructureOpInputNV {
        VkClusterAccelerationStructureClustersBottomLevelInputNV* pClustersBottomLevel;
        VkClusterAccelerationStructureTriangleClusterInputNV* pTriangleClusters;
        VkClusterAccelerationStructureMoveObjectsInputNV* pMoveObjects;
    };

    struct VkClusterAccelerationStructureInputInfoNV {
        VkStructureType sType;
        void* pNext;
        uint32_t maxAccelerationStructureCount;
        VkBuildAccelerationStructureFlagsKHR flags;
        VkClusterAccelerationStructureOpTypeNV opType;
        VkClusterAccelerationStructureOpModeNV opMode;
        VkClusterAccelerationStructureOpInputNV opInput;
    };

    struct VkStridedDeviceAddressRegionKHR {
        VkDeviceAddress deviceAddress;
        VkDeviceSize stride;
        VkDeviceSize size;
    };

    struct VkClusterAccelerationStructureCommandsInfoNV {
        VkStructureType sType;
        void* pNext;
        VkClusterAccelerationStructureInputInfoNV input;
        VkDeviceAddress dstImplicitData;
        VkDeviceAddress scratchData;
        VkStridedDeviceAddressRegionKHR dstAddressesArray;
        VkStridedDeviceAddressRegionKHR dstSizesArray;
        VkStridedDeviceAddressRegionKHR srcInfosArray;
        VkDeviceAddress srcInfosCount;
        VkClusterAccelerationStructureAddressResolutionFlagsNV addressResolutionFlags;
    };

    struct VkPhysicalDeviceMultiDrawPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t maxMultiDrawCount;
    };

    struct VkGraphicsShaderGroupCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t stageCount;
        const VkPipelineShaderStageCreateInfo* pStages;
        const VkPipelineVertexInputStateCreateInfo* pVertexInputState;
        const VkPipelineTessellationStateCreateInfo* pTessellationState;
    };

    struct VkGraphicsPipelineShaderGroupsCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t groupCount;
        const VkGraphicsShaderGroupCreateInfoNV* pGroups;
        uint32_t pipelineCount;
        const VkPipeline* pPipelines;
    };

    struct VkBindShaderGroupIndirectCommandNV {
        uint32_t groupIndex;
    };

    struct VkBindIndexBufferIndirectCommandNV {
        VkDeviceAddress bufferAddress;
        uint32_t size;
        VkIndexType indexType;
    };

    struct VkBindVertexBufferIndirectCommandNV {
        VkDeviceAddress bufferAddress;
        uint32_t size;
        uint32_t stride;
    };

    struct VkSetStateFlagsIndirectCommandNV {
        uint32_t data;
    };

    struct VkIndirectCommandsStreamNV {
        VkBuffer buffer;
        VkDeviceSize offset;
    };

    struct VkIndirectCommandsLayoutTokenNV {
        VkStructureType sType;
        const void* pNext;
        VkIndirectCommandsTokenTypeNV tokenType;
        uint32_t stream;
        uint32_t offset;
        uint32_t vertexBindingUnit;
        VkBool32 vertexDynamicStride;
        VkPipelineLayout pushconstantPipelineLayout;
        VkShaderStageFlags pushconstantShaderStageFlags;
        uint32_t pushconstantOffset;
        uint32_t pushconstantSize;
        VkIndirectStateFlagsNV indirectStateFlags;
        uint32_t indexTypeCount;
        const VkIndexType* pIndexTypes;
        const uint32_t* pIndexTypeValues;
    };

    struct VkIndirectCommandsLayoutCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkIndirectCommandsLayoutUsageFlagsNV flags;
        VkPipelineBindPoint pipelineBindPoint;
        uint32_t tokenCount;
        const VkIndirectCommandsLayoutTokenNV* pTokens;
        uint32_t streamCount;
        const uint32_t* pStreamStrides;
    };

    struct VkGeneratedCommandsInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkPipelineBindPoint pipelineBindPoint;
        VkPipeline pipeline;
        VkIndirectCommandsLayoutNV indirectCommandsLayout;
        uint32_t streamCount;
        const VkIndirectCommandsStreamNV* pStreams;
        uint32_t sequencesCount;
        VkBuffer preprocessBuffer;
        VkDeviceSize preprocessOffset;
        VkDeviceSize preprocessSize;
        VkBuffer sequencesCountBuffer;
        VkDeviceSize sequencesCountOffset;
        VkBuffer sequencesIndexBuffer;
        VkDeviceSize sequencesIndexOffset;
    };

    struct VkGeneratedCommandsMemoryRequirementsInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkPipelineBindPoint pipelineBindPoint;
        VkPipeline pipeline;
        VkIndirectCommandsLayoutNV indirectCommandsLayout;
        uint32_t maxSequencesCount;
    };

    struct VkPipelineIndirectDeviceAddressInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkPipelineBindPoint pipelineBindPoint;
        VkPipeline pipeline;
    };

    struct VkBindPipelineIndirectCommandNV {
        VkDeviceAddress pipelineAddress;
    };

    struct VkPhysicalDeviceFeatures2 {
        VkStructureType sType;
        void* pNext;
        VkPhysicalDeviceFeatures features;
    };

    struct VkPhysicalDeviceFeatures2KHR {
    };

    struct VkPhysicalDeviceProperties2 {
        VkStructureType sType;
        void* pNext;
        VkPhysicalDeviceProperties properties;
    };

    struct VkPhysicalDeviceProperties2KHR {
    };

    struct VkFormatProperties2 {
        VkStructureType sType;
        void* pNext;
        VkFormatProperties formatProperties;
    };

    struct VkFormatProperties2KHR {
    };

    struct VkImageFormatProperties2 {
        VkStructureType sType;
        void* pNext;
        VkImageFormatProperties imageFormatProperties;
    };

    struct VkImageFormatProperties2KHR {
    };

    struct VkPhysicalDeviceImageFormatInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkFormat format;
        VkImageType type;
        VkImageTiling tiling;
        VkImageUsageFlags usage;
        VkImageCreateFlags flags;
    };

    struct VkPhysicalDeviceImageFormatInfo2KHR {
    };

    struct VkQueueFamilyProperties2 {
        VkStructureType sType;
        void* pNext;
        VkQueueFamilyProperties queueFamilyProperties;
    };

    struct VkQueueFamilyProperties2KHR {
    };

    struct VkPhysicalDeviceMemoryProperties2 {
        VkStructureType sType;
        void* pNext;
        VkPhysicalDeviceMemoryProperties memoryProperties;
    };

    struct VkPhysicalDeviceMemoryProperties2KHR {
    };

    struct VkSparseImageFormatProperties2 {
        VkStructureType sType;
        void* pNext;
        VkSparseImageFormatProperties properties;
    };

    struct VkSparseImageFormatProperties2KHR {
    };

    struct VkPhysicalDeviceSparseImageFormatInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkFormat format;
        VkImageType type;
        VkSampleCountFlagBits samples;
        VkImageUsageFlags usage;
        VkImageTiling tiling;
    };

    struct VkPhysicalDeviceSparseImageFormatInfo2KHR {
    };

    struct VkPhysicalDevicePushDescriptorProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t maxPushDescriptors;
    };

    struct VkPhysicalDevicePushDescriptorPropertiesKHR {
    };

    struct VkConformanceVersion {
        uint8_t major;
        uint8_t minor;
        uint8_t subminor;
        uint8_t patch;
    };

    struct VkConformanceVersionKHR {
    };

    struct VkPhysicalDeviceDriverProperties {
        VkStructureType sType;
        void* pNext;
        VkDriverId driverID;
        char driverName[256];
        char driverInfo[256];
        VkConformanceVersion conformanceVersion;
    };

    struct VkPhysicalDeviceDriverPropertiesKHR {
    };

    struct VkPresentRegionsKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t swapchainCount;
        const VkPresentRegionKHR* pRegions;
    };

    struct VkPresentRegionKHR {
        uint32_t rectangleCount;
        const VkRectLayerKHR* pRectangles;
    };

    struct VkRectLayerKHR {
        VkOffset2D offset;
        VkExtent2D extent;
        uint32_t layer;
    };

    struct VkPhysicalDeviceVariablePointersFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 variablePointersStorageBuffer;
        VkBool32 variablePointers;
    };

    struct VkPhysicalDeviceVariablePointersFeaturesKHR {
    };

    struct VkPhysicalDeviceVariablePointerFeaturesKHR {
    };

    struct VkPhysicalDeviceVariablePointerFeatures {
    };

    struct VkExternalMemoryProperties {
        VkExternalMemoryFeatureFlags externalMemoryFeatures;
        VkExternalMemoryHandleTypeFlags exportFromImportedHandleTypes;
        VkExternalMemoryHandleTypeFlags compatibleHandleTypes;
    };

    struct VkExternalMemoryPropertiesKHR {
    };

    struct VkPhysicalDeviceExternalImageFormatInfo {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlagBits handleType;
    };

    struct VkPhysicalDeviceExternalImageFormatInfoKHR {
    };

    struct VkExternalImageFormatProperties {
        VkStructureType sType;
        void* pNext;
        VkExternalMemoryProperties externalMemoryProperties;
    };

    struct VkExternalImageFormatPropertiesKHR {
    };

    struct VkPhysicalDeviceExternalBufferInfo {
        VkStructureType sType;
        const void* pNext;
        VkBufferCreateFlags flags;
        VkBufferUsageFlags usage;
        VkExternalMemoryHandleTypeFlagBits handleType;
    };

    struct VkPhysicalDeviceExternalBufferInfoKHR {
    };

    struct VkExternalBufferProperties {
        VkStructureType sType;
        void* pNext;
        VkExternalMemoryProperties externalMemoryProperties;
    };

    struct VkExternalBufferPropertiesKHR {
    };

    struct VkPhysicalDeviceIDProperties {
        VkStructureType sType;
        void* pNext;
        uint8_t deviceUUID[16];
        uint8_t driverUUID[16];
        uint8_t deviceLUID[8];
        uint32_t deviceNodeMask;
        VkBool32 deviceLUIDValid;
    };

    struct VkPhysicalDeviceIDPropertiesKHR {
    };

    struct VkExternalMemoryImageCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlags handleTypes;
    };

    struct VkExternalMemoryImageCreateInfoKHR {
    };

    struct VkExternalMemoryBufferCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlags handleTypes;
    };

    struct VkExternalMemoryBufferCreateInfoKHR {
    };

    struct VkExportMemoryAllocateInfo {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlags handleTypes;
    };

    struct VkExportMemoryAllocateInfoKHR {
    };

    struct VkImportMemoryWin32HandleInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlagBits handleType;
        HANDLE handle;
        LPCWSTR name;
    };

    struct VkExportMemoryWin32HandleInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const SECURITY_ATTRIBUTES* pAttributes;
        DWORD dwAccess;
        LPCWSTR name;
    };

    struct VkImportMemoryZirconHandleInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlagBits handleType;
        zx_handle_t handle;
    };

    struct VkMemoryZirconHandlePropertiesFUCHSIA {
        VkStructureType sType;
        void* pNext;
        uint32_t memoryTypeBits;
    };

    struct VkMemoryGetZirconHandleInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
        VkExternalMemoryHandleTypeFlagBits handleType;
    };

    struct VkMemoryWin32HandlePropertiesKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t memoryTypeBits;
    };

    struct VkMemoryGetWin32HandleInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
        VkExternalMemoryHandleTypeFlagBits handleType;
    };

    struct VkImportMemoryFdInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlagBits handleType;
        int fd;
    };

    struct VkMemoryFdPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t memoryTypeBits;
    };

    struct VkMemoryGetFdInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
        VkExternalMemoryHandleTypeFlagBits handleType;
    };

    struct VkWin32KeyedMutexAcquireReleaseInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t acquireCount;
        const VkDeviceMemory* pAcquireSyncs;
        const uint64_t* pAcquireKeys;
        const uint32_t* pAcquireTimeouts;
        uint32_t releaseCount;
        const VkDeviceMemory* pReleaseSyncs;
        const uint64_t* pReleaseKeys;
    };

    struct VkImportMemoryMetalHandleInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlagBits handleType;
        void* handle;
    };

    struct VkMemoryMetalHandlePropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t memoryTypeBits;
    };

    struct VkMemoryGetMetalHandleInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
        VkExternalMemoryHandleTypeFlagBits handleType;
    };

    struct VkPhysicalDeviceExternalSemaphoreInfo {
        VkStructureType sType;
        const void* pNext;
        VkExternalSemaphoreHandleTypeFlagBits handleType;
    };

    struct VkPhysicalDeviceExternalSemaphoreInfoKHR {
    };

    struct VkExternalSemaphoreProperties {
        VkStructureType sType;
        void* pNext;
        VkExternalSemaphoreHandleTypeFlags exportFromImportedHandleTypes;
        VkExternalSemaphoreHandleTypeFlags compatibleHandleTypes;
        VkExternalSemaphoreFeatureFlags externalSemaphoreFeatures;
    };

    struct VkExternalSemaphorePropertiesKHR {
    };

    struct VkExportSemaphoreCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkExternalSemaphoreHandleTypeFlags handleTypes;
    };

    struct VkExportSemaphoreCreateInfoKHR {
    };

    struct VkImportSemaphoreWin32HandleInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore semaphore;
        VkSemaphoreImportFlags flags;
        VkExternalSemaphoreHandleTypeFlagBits handleType;
        HANDLE handle;
        LPCWSTR name;
    };

    struct VkExportSemaphoreWin32HandleInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const SECURITY_ATTRIBUTES* pAttributes;
        DWORD dwAccess;
        LPCWSTR name;
    };

    struct VkD3D12FenceSubmitInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t waitSemaphoreValuesCount;
        const uint64_t* pWaitSemaphoreValues;
        uint32_t signalSemaphoreValuesCount;
        const uint64_t* pSignalSemaphoreValues;
    };

    struct VkSemaphoreGetWin32HandleInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore semaphore;
        VkExternalSemaphoreHandleTypeFlagBits handleType;
    };

    struct VkImportSemaphoreFdInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore semaphore;
        VkSemaphoreImportFlags flags;
        VkExternalSemaphoreHandleTypeFlagBits handleType;
        int fd;
    };

    struct VkSemaphoreGetFdInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore semaphore;
        VkExternalSemaphoreHandleTypeFlagBits handleType;
    };

    struct VkImportSemaphoreZirconHandleInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore semaphore;
        VkSemaphoreImportFlags flags;
        VkExternalSemaphoreHandleTypeFlagBits handleType;
        zx_handle_t zirconHandle;
    };

    struct VkSemaphoreGetZirconHandleInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore semaphore;
        VkExternalSemaphoreHandleTypeFlagBits handleType;
    };

    struct VkPhysicalDeviceExternalFenceInfo {
        VkStructureType sType;
        const void* pNext;
        VkExternalFenceHandleTypeFlagBits handleType;
    };

    struct VkPhysicalDeviceExternalFenceInfoKHR {
    };

    struct VkExternalFenceProperties {
        VkStructureType sType;
        void* pNext;
        VkExternalFenceHandleTypeFlags exportFromImportedHandleTypes;
        VkExternalFenceHandleTypeFlags compatibleHandleTypes;
        VkExternalFenceFeatureFlags externalFenceFeatures;
    };

    struct VkExternalFencePropertiesKHR {
    };

    struct VkExportFenceCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkExternalFenceHandleTypeFlags handleTypes;
    };

    struct VkExportFenceCreateInfoKHR {
    };

    struct VkImportFenceWin32HandleInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkFence fence;
        VkFenceImportFlags flags;
        VkExternalFenceHandleTypeFlagBits handleType;
        HANDLE handle;
        LPCWSTR name;
    };

    struct VkExportFenceWin32HandleInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const SECURITY_ATTRIBUTES* pAttributes;
        DWORD dwAccess;
        LPCWSTR name;
    };

    struct VkFenceGetWin32HandleInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkFence fence;
        VkExternalFenceHandleTypeFlagBits handleType;
    };

    struct VkImportFenceFdInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkFence fence;
        VkFenceImportFlags flags;
        VkExternalFenceHandleTypeFlagBits handleType;
        int fd;
    };

    struct VkFenceGetFdInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkFence fence;
        VkExternalFenceHandleTypeFlagBits handleType;
    };

    struct VkExportFenceSciSyncInfoNV {
        VkStructureType sType;
        const void* pNext;
        NvSciSyncAttrList pAttributes;
    };

    struct VkImportFenceSciSyncInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkFence fence;
        VkExternalFenceHandleTypeFlagBits handleType;
        void* handle;
    };

    struct VkFenceGetSciSyncInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkFence fence;
        VkExternalFenceHandleTypeFlagBits handleType;
    };

    struct VkExportSemaphoreSciSyncInfoNV {
        VkStructureType sType;
        const void* pNext;
        NvSciSyncAttrList pAttributes;
    };

    struct VkImportSemaphoreSciSyncInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore semaphore;
        VkExternalSemaphoreHandleTypeFlagBits handleType;
        void* handle;
    };

    struct VkSemaphoreGetSciSyncInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore semaphore;
        VkExternalSemaphoreHandleTypeFlagBits handleType;
    };

    struct VkSciSyncAttributesInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkSciSyncClientTypeNV clientType;
        VkSciSyncPrimitiveTypeNV primitiveType;
    };

    struct VkPhysicalDeviceExternalSciSyncFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 sciSyncFence;
        VkBool32 sciSyncSemaphore;
        VkBool32 sciSyncImport;
        VkBool32 sciSyncExport;
    };

    struct VkPhysicalDeviceExternalSciSync2FeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 sciSyncFence;
        VkBool32 sciSyncSemaphore2;
        VkBool32 sciSyncImport;
        VkBool32 sciSyncExport;
    };

    struct VkSemaphoreSciSyncPoolCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        NvSciSyncObj handle;
    };

    struct VkSemaphoreSciSyncCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkSemaphoreSciSyncPoolNV semaphorePool;
        const NvSciSyncFence* pFence;
    };

    struct VkDeviceSemaphoreSciSyncPoolReservationCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t semaphoreSciSyncPoolRequestCount;
    };

    struct VkPhysicalDeviceMultiviewFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 multiview;
        VkBool32 multiviewGeometryShader;
        VkBool32 multiviewTessellationShader;
    };

    struct VkPhysicalDeviceMultiviewFeaturesKHR {
    };

    struct VkPhysicalDeviceMultiviewProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t maxMultiviewViewCount;
        uint32_t maxMultiviewInstanceIndex;
    };

    struct VkPhysicalDeviceMultiviewPropertiesKHR {
    };

    struct VkRenderPassMultiviewCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t subpassCount;
        const uint32_t* pViewMasks;
        uint32_t dependencyCount;
        const int32_t* pViewOffsets;
        uint32_t correlationMaskCount;
        const uint32_t* pCorrelationMasks;
    };

    struct VkRenderPassMultiviewCreateInfoKHR {
    };

    struct VkSurfaceCapabilities2EXT {
        VkStructureType sType;
        void* pNext;
        uint32_t minImageCount;
        uint32_t maxImageCount;
        VkExtent2D currentExtent;
        VkExtent2D minImageExtent;
        VkExtent2D maxImageExtent;
        uint32_t maxImageArrayLayers;
        VkSurfaceTransformFlagsKHR supportedTransforms;
        VkSurfaceTransformFlagBitsKHR currentTransform;
        VkCompositeAlphaFlagsKHR supportedCompositeAlpha;
        VkImageUsageFlags supportedUsageFlags;
        VkSurfaceCounterFlagsEXT supportedSurfaceCounters;
    };

    struct VkDisplayPowerInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDisplayPowerStateEXT powerState;
    };

    struct VkDeviceEventInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDeviceEventTypeEXT deviceEvent;
    };

    struct VkDisplayEventInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDisplayEventTypeEXT displayEvent;
    };

    struct VkSwapchainCounterCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkSurfaceCounterFlagsEXT surfaceCounters;
    };

    struct VkPhysicalDeviceGroupProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t physicalDeviceCount;
        VkPhysicalDevice physicalDevices[32];
        VkBool32 subsetAllocation;
    };

    struct VkPhysicalDeviceGroupPropertiesKHR {
    };

    struct VkMemoryAllocateFlagsInfo {
        VkStructureType sType;
        const void* pNext;
        VkMemoryAllocateFlags flags;
        uint32_t deviceMask;
    };

    struct VkMemoryAllocateFlagsInfoKHR {
    };

    struct VkBindBufferMemoryInfo {
        VkStructureType sType;
        const void* pNext;
        VkBuffer buffer;
        VkDeviceMemory memory;
        VkDeviceSize memoryOffset;
    };

    struct VkBindBufferMemoryInfoKHR {
    };

    struct VkBindBufferMemoryDeviceGroupInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t deviceIndexCount;
        const uint32_t* pDeviceIndices;
    };

    struct VkBindBufferMemoryDeviceGroupInfoKHR {
    };

    struct VkBindImageMemoryInfo {
        VkStructureType sType;
        const void* pNext;
        VkImage image;
        VkDeviceMemory memory;
        VkDeviceSize memoryOffset;
    };

    struct VkBindImageMemoryInfoKHR {
    };

    struct VkBindImageMemoryDeviceGroupInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t deviceIndexCount;
        const uint32_t* pDeviceIndices;
        uint32_t splitInstanceBindRegionCount;
        const VkRect2D* pSplitInstanceBindRegions;
    };

    struct VkBindImageMemoryDeviceGroupInfoKHR {
    };

    struct VkDeviceGroupRenderPassBeginInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t deviceMask;
        uint32_t deviceRenderAreaCount;
        const VkRect2D* pDeviceRenderAreas;
    };

    struct VkDeviceGroupRenderPassBeginInfoKHR {
    };

    struct VkDeviceGroupCommandBufferBeginInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t deviceMask;
    };

    struct VkDeviceGroupCommandBufferBeginInfoKHR {
    };

    struct VkDeviceGroupSubmitInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t waitSemaphoreCount;
        const uint32_t* pWaitSemaphoreDeviceIndices;
        uint32_t commandBufferCount;
        const uint32_t* pCommandBufferDeviceMasks;
        uint32_t signalSemaphoreCount;
        const uint32_t* pSignalSemaphoreDeviceIndices;
    };

    struct VkDeviceGroupSubmitInfoKHR {
    };

    struct VkDeviceGroupBindSparseInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t resourceDeviceIndex;
        uint32_t memoryDeviceIndex;
    };

    struct VkDeviceGroupBindSparseInfoKHR {
    };

    struct VkDeviceGroupPresentCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t presentMask[32];
        VkDeviceGroupPresentModeFlagsKHR modes;
    };

    struct VkImageSwapchainCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkSwapchainKHR swapchain;
    };

    struct VkBindImageMemorySwapchainInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkSwapchainKHR swapchain;
        uint32_t imageIndex;
    };

    struct VkAcquireNextImageInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkSwapchainKHR swapchain;
        uint64_t timeout;
        VkSemaphore semaphore;
        VkFence fence;
        uint32_t deviceMask;
    };

    struct VkDeviceGroupPresentInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t swapchainCount;
        const uint32_t* pDeviceMasks;
        VkDeviceGroupPresentModeFlagBitsKHR mode;
    };

    struct VkDeviceGroupDeviceCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t physicalDeviceCount;
        const VkPhysicalDevice* pPhysicalDevices;
    };

    struct VkDeviceGroupDeviceCreateInfoKHR {
    };

    struct VkDeviceGroupSwapchainCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkDeviceGroupPresentModeFlagsKHR modes;
    };

    struct VkDescriptorUpdateTemplateEntry {
        uint32_t dstBinding;
        uint32_t dstArrayElement;
        uint32_t descriptorCount;
        VkDescriptorType descriptorType;
        size_t offset;
        size_t stride;
    };

    struct VkDescriptorUpdateTemplateEntryKHR {
    };

    struct VkDescriptorUpdateTemplateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkDescriptorUpdateTemplateCreateFlags flags;
        uint32_t descriptorUpdateEntryCount;
        const VkDescriptorUpdateTemplateEntry* pDescriptorUpdateEntries;
        VkDescriptorUpdateTemplateType templateType;
        VkDescriptorSetLayout descriptorSetLayout;
        VkPipelineBindPoint pipelineBindPoint;
        VkPipelineLayout pipelineLayout;
        uint32_t set;
    };

    struct VkDescriptorUpdateTemplateCreateInfoKHR {
    };

    struct VkXYColorEXT {
        float x;
        float y;
    };

    struct VkPhysicalDevicePresentIdFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentId;
    };

    struct VkPresentIdKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t swapchainCount;
        const uint64_t* pPresentIds;
    };

    struct VkPhysicalDevicePresentId2FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentId2;
    };

    struct VkPresentId2KHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t swapchainCount;
        const uint64_t* pPresentIds;
    };

    struct VkPresentWait2InfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint64_t presentId;
        uint64_t timeout;
    };

    struct VkPhysicalDevicePresentWaitFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentWait;
    };

    struct VkPhysicalDevicePresentWait2FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentWait2;
    };

    struct VkPhysicalDevicePresentTimingFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentTiming;
        VkBool32 presentAtAbsoluteTime;
        VkBool32 presentAtRelativeTime;
    };

    struct VkPresentTimingSurfaceCapabilitiesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentTimingSupported;
        VkBool32 presentAtAbsoluteTimeSupported;
        VkBool32 presentAtRelativeTimeSupported;
        VkPresentStageFlagsEXT presentStageQueries;
    };

    struct VkSwapchainTimingPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint64_t refreshDuration;
        uint64_t refreshInterval;
    };

    struct VkSwapchainTimeDomainPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t timeDomainCount;
        VkTimeDomainKHR* pTimeDomains;
        uint64_t* pTimeDomainIds;
    };

    struct VkPresentStageTimeEXT {
        VkPresentStageFlagsEXT stage;
        uint64_t time;
    };

    struct VkPastPresentationTimingInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkPastPresentationTimingFlagsEXT flags;
        VkSwapchainKHR swapchain;
    };

    struct VkPastPresentationTimingPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint64_t timingPropertiesCounter;
        uint64_t timeDomainsCounter;
        uint32_t presentationTimingCount;
        VkPastPresentationTimingEXT* pPresentationTimings;
    };

    struct VkPastPresentationTimingEXT {
        VkStructureType sType;
        void* pNext;
        uint64_t presentId;
        uint64_t targetTime;
        uint32_t presentStageCount;
        VkPresentStageTimeEXT* pPresentStages;
        VkTimeDomainKHR timeDomain;
        uint64_t timeDomainId;
        VkBool32 reportComplete;
    };

    struct VkPresentTimingsInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t swapchainCount;
        const VkPresentTimingInfoEXT* pTimingInfos;
    };

    struct VkPresentTimingInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkPresentTimingInfoFlagsEXT flags;
        uint64_t targetTime;
        uint64_t timeDomainId;
        VkPresentStageFlagsEXT presentStageQueries;
        VkPresentStageFlagsEXT targetTimeDomainPresentStage;
    };

    struct VkSwapchainCalibratedTimestampInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkSwapchainKHR swapchain;
        VkPresentStageFlagsEXT presentStage;
        uint64_t timeDomainId;
    };

    struct VkHdrMetadataEXT {
        VkStructureType sType;
        const void* pNext;
        VkXYColorEXT displayPrimaryRed;
        VkXYColorEXT displayPrimaryGreen;
        VkXYColorEXT displayPrimaryBlue;
        VkXYColorEXT whitePoint;
        float maxLuminance;
        float minLuminance;
        float maxContentLightLevel;
        float maxFrameAverageLightLevel;
    };

    struct VkHdrVividDynamicMetadataHUAWEI {
        VkStructureType sType;
        const void* pNext;
        size_t dynamicMetadataSize;
        const void* pDynamicMetadata;
    };

    struct VkDisplayNativeHdrSurfaceCapabilitiesAMD {
        VkStructureType sType;
        void* pNext;
        VkBool32 localDimmingSupport;
    };

    struct VkSwapchainDisplayNativeHdrCreateInfoAMD {
        VkStructureType sType;
        const void* pNext;
        VkBool32 localDimmingEnable;
    };

    struct VkRefreshCycleDurationGOOGLE {
        uint64_t refreshDuration;
    };

    struct VkPastPresentationTimingGOOGLE {
        uint32_t presentID;
        uint64_t desiredPresentTime;
        uint64_t actualPresentTime;
        uint64_t earliestPresentTime;
        uint64_t presentMargin;
    };

    struct VkPresentTimesInfoGOOGLE {
        VkStructureType sType;
        const void* pNext;
        uint32_t swapchainCount;
        const VkPresentTimeGOOGLE* pTimes;
    };

    struct VkPresentTimeGOOGLE {
        uint32_t presentID;
        uint64_t desiredPresentTime;
    };

    struct VkIOSSurfaceCreateInfoMVK {
        VkStructureType sType;
        const void* pNext;
        VkIOSSurfaceCreateFlagsMVK flags;
        const void* pView;
    };

    struct VkMacOSSurfaceCreateInfoMVK {
        VkStructureType sType;
        const void* pNext;
        VkMacOSSurfaceCreateFlagsMVK flags;
        const void* pView;
    };

    struct VkMetalSurfaceCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkMetalSurfaceCreateFlagsEXT flags;
        const CAMetalLayer* pLayer;
    };

    struct VkViewportWScalingNV {
        float xcoeff;
        float ycoeff;
    };

    struct VkPipelineViewportWScalingStateCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkBool32 viewportWScalingEnable;
        uint32_t viewportCount;
        const VkViewportWScalingNV* pViewportWScalings;
    };

    struct VkViewportSwizzleNV {
        VkViewportCoordinateSwizzleNV x;
        VkViewportCoordinateSwizzleNV y;
        VkViewportCoordinateSwizzleNV z;
        VkViewportCoordinateSwizzleNV w;
    };

    struct VkPipelineViewportSwizzleStateCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkPipelineViewportSwizzleStateCreateFlagsNV flags;
        uint32_t viewportCount;
        const VkViewportSwizzleNV* pViewportSwizzles;
    };

    struct VkPhysicalDeviceDiscardRectanglePropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t maxDiscardRectangles;
    };

    struct VkPipelineDiscardRectangleStateCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkPipelineDiscardRectangleStateCreateFlagsEXT flags;
        VkDiscardRectangleModeEXT discardRectangleMode;
        uint32_t discardRectangleCount;
        const VkRect2D* pDiscardRectangles;
    };

    struct VkPhysicalDeviceMultiviewPerViewAttributesPropertiesNVX {
        VkStructureType sType;
        void* pNext;
        VkBool32 perViewPositionAllComponents;
    };

    struct VkInputAttachmentAspectReference {
        uint32_t subpass;
        uint32_t inputAttachmentIndex;
        VkImageAspectFlags aspectMask;
    };

    struct VkInputAttachmentAspectReferenceKHR {
    };

    struct VkRenderPassInputAttachmentAspectCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t aspectReferenceCount;
        const VkInputAttachmentAspectReference* pAspectReferences;
    };

    struct VkRenderPassInputAttachmentAspectCreateInfoKHR {
    };

    struct VkPhysicalDeviceSurfaceInfo2KHR {
        VkStructureType sType;
        const void* pNext;
        VkSurfaceKHR surface;
    };

    struct VkSurfaceCapabilities2KHR {
        VkStructureType sType;
        void* pNext;
        VkSurfaceCapabilitiesKHR surfaceCapabilities;
    };

    struct VkSurfaceFormat2KHR {
        VkStructureType sType;
        void* pNext;
        VkSurfaceFormatKHR surfaceFormat;
    };

    struct VkDisplayProperties2KHR {
        VkStructureType sType;
        void* pNext;
        VkDisplayPropertiesKHR displayProperties;
    };

    struct VkDisplayPlaneProperties2KHR {
        VkStructureType sType;
        void* pNext;
        VkDisplayPlanePropertiesKHR displayPlaneProperties;
    };

    struct VkDisplayModeProperties2KHR {
        VkStructureType sType;
        void* pNext;
        VkDisplayModePropertiesKHR displayModeProperties;
    };

    struct VkDisplayModeStereoPropertiesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 hdmi3DSupported;
    };

    struct VkDisplayPlaneInfo2KHR {
        VkStructureType sType;
        const void* pNext;
        VkDisplayModeKHR mode;
        uint32_t planeIndex;
    };

    struct VkDisplayPlaneCapabilities2KHR {
        VkStructureType sType;
        void* pNext;
        VkDisplayPlaneCapabilitiesKHR capabilities;
    };

    struct VkSharedPresentSurfaceCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        VkImageUsageFlags sharedPresentSupportedUsageFlags;
    };

    struct VkPhysicalDevice16BitStorageFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 storageBuffer16BitAccess;
        VkBool32 uniformAndStorageBuffer16BitAccess;
        VkBool32 storagePushConstant16;
        VkBool32 storageInputOutput16;
    };

    struct VkPhysicalDevice16BitStorageFeaturesKHR {
    };

    struct VkPhysicalDeviceSubgroupProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t subgroupSize;
        VkShaderStageFlags supportedStages;
        VkSubgroupFeatureFlags supportedOperations;
        VkBool32 quadOperationsInAllStages;
    };

    struct VkPhysicalDeviceShaderSubgroupExtendedTypesFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderSubgroupExtendedTypes;
    };

    struct VkPhysicalDeviceShaderSubgroupExtendedTypesFeaturesKHR {
    };

    struct VkBufferMemoryRequirementsInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkBuffer buffer;
    };

    struct VkBufferMemoryRequirementsInfo2KHR {
    };

    struct VkDeviceBufferMemoryRequirements {
        VkStructureType sType;
        const void* pNext;
        const VkBufferCreateInfo* pCreateInfo;
    };

    struct VkDeviceBufferMemoryRequirementsKHR {
    };

    struct VkImageMemoryRequirementsInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkImage image;
    };

    struct VkImageMemoryRequirementsInfo2KHR {
    };

    struct VkImageSparseMemoryRequirementsInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkImage image;
    };

    struct VkImageSparseMemoryRequirementsInfo2KHR {
    };

    struct VkDeviceImageMemoryRequirements {
        VkStructureType sType;
        const void* pNext;
        const VkImageCreateInfo* pCreateInfo;
        VkImageAspectFlagBits planeAspect;
    };

    struct VkDeviceImageMemoryRequirementsKHR {
    };

    struct VkMemoryRequirements2 {
        VkStructureType sType;
        void* pNext;
        VkMemoryRequirements memoryRequirements;
    };

    struct VkMemoryRequirements2KHR {
    };

    struct VkSparseImageMemoryRequirements2 {
        VkStructureType sType;
        void* pNext;
        VkSparseImageMemoryRequirements memoryRequirements;
    };

    struct VkSparseImageMemoryRequirements2KHR {
    };

    struct VkPhysicalDevicePointClippingProperties {
        VkStructureType sType;
        void* pNext;
        VkPointClippingBehavior pointClippingBehavior;
    };

    struct VkPhysicalDevicePointClippingPropertiesKHR {
    };

    struct VkMemoryDedicatedRequirements {
        VkStructureType sType;
        void* pNext;
        VkBool32 prefersDedicatedAllocation;
        VkBool32 requiresDedicatedAllocation;
    };

    struct VkMemoryDedicatedRequirementsKHR {
    };

    struct VkMemoryDedicatedAllocateInfo {
        VkStructureType sType;
        const void* pNext;
        VkImage image;
        VkBuffer buffer;
    };

    struct VkMemoryDedicatedAllocateInfoKHR {
    };

    struct VkImageViewUsageCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkImageUsageFlags usage;
    };

    struct VkImageViewSlicedCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t sliceOffset;
        uint32_t sliceCount;
    };

    struct VkImageViewUsageCreateInfoKHR {
    };

    struct VkPipelineTessellationDomainOriginStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkTessellationDomainOrigin domainOrigin;
    };

    struct VkPipelineTessellationDomainOriginStateCreateInfoKHR {
    };

    struct VkSamplerYcbcrConversionInfo {
        VkStructureType sType;
        const void* pNext;
        VkSamplerYcbcrConversion conversion;
    };

    struct VkSamplerYcbcrConversionInfoKHR {
    };

    struct VkSamplerYcbcrConversionCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkFormat format;
        VkSamplerYcbcrModelConversion ycbcrModel;
        VkSamplerYcbcrRange ycbcrRange;
        VkComponentMapping components;
        VkChromaLocation xChromaOffset;
        VkChromaLocation yChromaOffset;
        VkFilter chromaFilter;
        VkBool32 forceExplicitReconstruction;
    };

    struct VkSamplerYcbcrConversionCreateInfoKHR {
    };

    struct VkBindImagePlaneMemoryInfo {
        VkStructureType sType;
        const void* pNext;
        VkImageAspectFlagBits planeAspect;
    };

    struct VkBindImagePlaneMemoryInfoKHR {
    };

    struct VkImagePlaneMemoryRequirementsInfo {
        VkStructureType sType;
        const void* pNext;
        VkImageAspectFlagBits planeAspect;
    };

    struct VkImagePlaneMemoryRequirementsInfoKHR {
    };

    struct VkPhysicalDeviceSamplerYcbcrConversionFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 samplerYcbcrConversion;
    };

    struct VkPhysicalDeviceSamplerYcbcrConversionFeaturesKHR {
    };

    struct VkSamplerYcbcrConversionImageFormatProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t combinedImageSamplerDescriptorCount;
    };

    struct VkSamplerYcbcrConversionImageFormatPropertiesKHR {
    };

    struct VkTextureLODGatherFormatPropertiesAMD {
        VkStructureType sType;
        void* pNext;
        VkBool32 supportsTextureGatherLODBiasAMD;
    };

    struct VkConditionalRenderingBeginInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkBuffer buffer;
        VkDeviceSize offset;
        VkConditionalRenderingFlagsEXT flags;
    };

    struct VkProtectedSubmitInfo {
        VkStructureType sType;
        const void* pNext;
        VkBool32 protectedSubmit;
    };

    struct VkPhysicalDeviceProtectedMemoryFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 protectedMemory;
    };

    struct VkPhysicalDeviceProtectedMemoryProperties {
        VkStructureType sType;
        void* pNext;
        VkBool32 protectedNoFault;
    };

    struct VkDeviceQueueInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkDeviceQueueCreateFlags flags;
        uint32_t queueFamilyIndex;
        uint32_t queueIndex;
    };

    struct VkPipelineCoverageToColorStateCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCoverageToColorStateCreateFlagsNV flags;
        VkBool32 coverageToColorEnable;
        uint32_t coverageToColorLocation;
    };

    struct VkPhysicalDeviceSamplerFilterMinmaxProperties {
        VkStructureType sType;
        void* pNext;
        VkBool32 filterMinmaxSingleComponentFormats;
        VkBool32 filterMinmaxImageComponentMapping;
    };

    struct VkPhysicalDeviceSamplerFilterMinmaxPropertiesEXT {
    };

    struct VkSampleLocationEXT {
        float x;
        float y;
    };

    struct VkSampleLocationsInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkSampleCountFlagBits sampleLocationsPerPixel;
        VkExtent2D sampleLocationGridSize;
        uint32_t sampleLocationsCount;
        const VkSampleLocationEXT* pSampleLocations;
    };

    struct VkAttachmentSampleLocationsEXT {
        uint32_t attachmentIndex;
        VkSampleLocationsInfoEXT sampleLocationsInfo;
    };

    struct VkSubpassSampleLocationsEXT {
        uint32_t subpassIndex;
        VkSampleLocationsInfoEXT sampleLocationsInfo;
    };

    struct VkRenderPassSampleLocationsBeginInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t attachmentInitialSampleLocationsCount;
        const VkAttachmentSampleLocationsEXT* pAttachmentInitialSampleLocations;
        uint32_t postSubpassSampleLocationsCount;
        const VkSubpassSampleLocationsEXT* pPostSubpassSampleLocations;
    };

    struct VkPipelineSampleLocationsStateCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkBool32 sampleLocationsEnable;
        VkSampleLocationsInfoEXT sampleLocationsInfo;
    };

    struct VkPhysicalDeviceSampleLocationsPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkSampleCountFlags sampleLocationSampleCounts;
        VkExtent2D maxSampleLocationGridSize;
        float sampleLocationCoordinateRange[2];
        uint32_t sampleLocationSubPixelBits;
        VkBool32 variableSampleLocations;
    };

    struct VkMultisamplePropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkExtent2D maxSampleLocationGridSize;
    };

    struct VkSamplerReductionModeCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkSamplerReductionMode reductionMode;
    };

    struct VkSamplerReductionModeCreateInfoEXT {
    };

    struct VkPhysicalDeviceBlendOperationAdvancedFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 advancedBlendCoherentOperations;
    };

    struct VkPhysicalDeviceMultiDrawFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 multiDraw;
    };

    struct VkPhysicalDeviceBlendOperationAdvancedPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t advancedBlendMaxColorAttachments;
        VkBool32 advancedBlendIndependentBlend;
        VkBool32 advancedBlendNonPremultipliedSrcColor;
        VkBool32 advancedBlendNonPremultipliedDstColor;
        VkBool32 advancedBlendCorrelatedOverlap;
        VkBool32 advancedBlendAllOperations;
    };

    struct VkPipelineColorBlendAdvancedStateCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkBool32 srcPremultiplied;
        VkBool32 dstPremultiplied;
        VkBlendOverlapEXT blendOverlap;
    };

    struct VkPhysicalDeviceInlineUniformBlockFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 inlineUniformBlock;
        VkBool32 descriptorBindingInlineUniformBlockUpdateAfterBind;
    };

    struct VkPhysicalDeviceInlineUniformBlockFeaturesEXT {
    };

    struct VkPhysicalDeviceInlineUniformBlockProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t maxInlineUniformBlockSize;
        uint32_t maxPerStageDescriptorInlineUniformBlocks;
        uint32_t maxPerStageDescriptorUpdateAfterBindInlineUniformBlocks;
        uint32_t maxDescriptorSetInlineUniformBlocks;
        uint32_t maxDescriptorSetUpdateAfterBindInlineUniformBlocks;
    };

    struct VkPhysicalDeviceInlineUniformBlockPropertiesEXT {
    };

    struct VkWriteDescriptorSetInlineUniformBlock {
        VkStructureType sType;
        const void* pNext;
        uint32_t dataSize;
        const void* pData;
    };

    struct VkWriteDescriptorSetInlineUniformBlockEXT {
    };

    struct VkDescriptorPoolInlineUniformBlockCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t maxInlineUniformBlockBindings;
    };

    struct VkDescriptorPoolInlineUniformBlockCreateInfoEXT {
    };

    struct VkPipelineCoverageModulationStateCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCoverageModulationStateCreateFlagsNV flags;
        VkCoverageModulationModeNV coverageModulationMode;
        VkBool32 coverageModulationTableEnable;
        uint32_t coverageModulationTableCount;
        const float* pCoverageModulationTable;
    };

    struct VkImageFormatListCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t viewFormatCount;
        const VkFormat* pViewFormats;
    };

    struct VkImageFormatListCreateInfoKHR {
    };

    struct VkValidationCacheCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkValidationCacheCreateFlagsEXT flags;
        size_t initialDataSize;
        const void* pInitialData;
    };

    struct VkShaderModuleValidationCacheCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkValidationCacheEXT validationCache;
    };

    struct VkPhysicalDeviceMaintenance3Properties {
        VkStructureType sType;
        void* pNext;
        uint32_t maxPerSetDescriptors;
        VkDeviceSize maxMemoryAllocationSize;
    };

    struct VkPhysicalDeviceMaintenance3PropertiesKHR {
    };

    struct VkPhysicalDeviceMaintenance4Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 maintenance4;
    };

    struct VkPhysicalDeviceMaintenance4FeaturesKHR {
    };

    struct VkPhysicalDeviceMaintenance4Properties {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize maxBufferSize;
    };

    struct VkPhysicalDeviceMaintenance4PropertiesKHR {
    };

    struct VkPhysicalDeviceMaintenance5Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 maintenance5;
    };

    struct VkPhysicalDeviceMaintenance5FeaturesKHR {
    };

    struct VkPhysicalDeviceMaintenance5Properties {
        VkStructureType sType;
        void* pNext;
        VkBool32 earlyFragmentMultisampleCoverageAfterSampleCounting;
        VkBool32 earlyFragmentSampleMaskTestBeforeSampleCounting;
        VkBool32 depthStencilSwizzleOneSupport;
        VkBool32 polygonModePointSize;
        VkBool32 nonStrictSinglePixelWideLinesUseParallelogram;
        VkBool32 nonStrictWideLinesUseParallelogram;
    };

    struct VkPhysicalDeviceMaintenance5PropertiesKHR {
    };

    struct VkPhysicalDeviceMaintenance6Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 maintenance6;
    };

    struct VkPhysicalDeviceMaintenance6FeaturesKHR {
    };

    struct VkPhysicalDeviceMaintenance6Properties {
        VkStructureType sType;
        void* pNext;
        VkBool32 blockTexelViewCompatibleMultipleLayers;
        uint32_t maxCombinedImageSamplerDescriptorCount;
        VkBool32 fragmentShadingRateClampCombinerInputs;
    };

    struct VkPhysicalDeviceMaintenance6PropertiesKHR {
    };

    struct VkPhysicalDeviceMaintenance7FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 maintenance7;
    };

    struct VkPhysicalDeviceMaintenance7PropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 robustFragmentShadingRateAttachmentAccess;
        VkBool32 separateDepthStencilAttachmentAccess;
        uint32_t maxDescriptorSetTotalUniformBuffersDynamic;
        uint32_t maxDescriptorSetTotalStorageBuffersDynamic;
        uint32_t maxDescriptorSetTotalBuffersDynamic;
        uint32_t maxDescriptorSetUpdateAfterBindTotalUniformBuffersDynamic;
        uint32_t maxDescriptorSetUpdateAfterBindTotalStorageBuffersDynamic;
        uint32_t maxDescriptorSetUpdateAfterBindTotalBuffersDynamic;
    };

    struct VkPhysicalDeviceLayeredApiPropertiesListKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t layeredApiCount;
        VkPhysicalDeviceLayeredApiPropertiesKHR* pLayeredApis;
    };

    struct VkPhysicalDeviceLayeredApiPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t vendorID;
        uint32_t deviceID;
        VkPhysicalDeviceLayeredApiKHR layeredAPI;
        char deviceName[256];
    };

    struct VkPhysicalDeviceLayeredApiVulkanPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkPhysicalDeviceProperties2 properties;
    };

    struct VkPhysicalDeviceMaintenance8FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 maintenance8;
    };

    struct VkPhysicalDeviceMaintenance9FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 maintenance9;
    };

    struct VkPhysicalDeviceMaintenance9PropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 image2DViewOf3DSparse;
        VkDefaultVertexAttributeValueKHR defaultVertexAttributeValue;
    };

    struct VkPhysicalDeviceMaintenance10PropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 rgba4OpaqueBlackSwizzled;
        VkBool32 resolveSrgbFormatAppliesTransferFunction;
        VkBool32 resolveSrgbFormatSupportsTransferFunctionControl;
    };

    struct VkPhysicalDeviceMaintenance10FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 maintenance10;
    };

    struct VkQueueFamilyOwnershipTransferPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t optimalImageTransferToQueueFamilies;
    };

    struct VkRenderingAreaInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t viewMask;
        uint32_t colorAttachmentCount;
        const VkFormat* pColorAttachmentFormats;
        VkFormat depthAttachmentFormat;
        VkFormat stencilAttachmentFormat;
    };

    struct VkRenderingAreaInfoKHR {
    };

    struct VkDescriptorSetLayoutSupport {
        VkStructureType sType;
        void* pNext;
        VkBool32 supported;
    };

    struct VkDescriptorSetLayoutSupportKHR {
    };

    struct VkPhysicalDeviceShaderDrawParametersFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderDrawParameters;
    };

    struct VkPhysicalDeviceShaderDrawParameterFeatures {
    };

    struct VkPhysicalDeviceShaderFloat16Int8Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderFloat16;
        VkBool32 shaderInt8;
    };

    struct VkPhysicalDeviceShaderFloat16Int8FeaturesKHR {
    };

    struct VkPhysicalDeviceFloat16Int8FeaturesKHR {
    };

    struct VkPhysicalDeviceFloatControlsProperties {
        VkStructureType sType;
        void* pNext;
        VkShaderFloatControlsIndependence denormBehaviorIndependence;
        VkShaderFloatControlsIndependence roundingModeIndependence;
        VkBool32 shaderSignedZeroInfNanPreserveFloat16;
        VkBool32 shaderSignedZeroInfNanPreserveFloat32;
        VkBool32 shaderSignedZeroInfNanPreserveFloat64;
        VkBool32 shaderDenormPreserveFloat16;
        VkBool32 shaderDenormPreserveFloat32;
        VkBool32 shaderDenormPreserveFloat64;
        VkBool32 shaderDenormFlushToZeroFloat16;
        VkBool32 shaderDenormFlushToZeroFloat32;
        VkBool32 shaderDenormFlushToZeroFloat64;
        VkBool32 shaderRoundingModeRTEFloat16;
        VkBool32 shaderRoundingModeRTEFloat32;
        VkBool32 shaderRoundingModeRTEFloat64;
        VkBool32 shaderRoundingModeRTZFloat16;
        VkBool32 shaderRoundingModeRTZFloat32;
        VkBool32 shaderRoundingModeRTZFloat64;
    };

    struct VkPhysicalDeviceFloatControlsPropertiesKHR {
    };

    struct VkPhysicalDeviceHostQueryResetFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 hostQueryReset;
    };

    struct VkPhysicalDeviceHostQueryResetFeaturesEXT {
    };

    struct VkNativeBufferUsage2ANDROID {
        uint64_t consumer;
        uint64_t producer;
    };

    struct VkNativeBufferANDROID {
        VkStructureType sType;
        const void* pNext;
        const void* handle;
        int stride;
        int format;
        int usage;
        VkNativeBufferUsage2ANDROID usage2;
    };

    struct VkSwapchainImageCreateInfoANDROID {
        VkStructureType sType;
        const void* pNext;
        VkSwapchainImageUsageFlagsANDROID usage;
    };

    struct VkPhysicalDevicePresentationPropertiesANDROID {
        VkStructureType sType;
        void* pNext;
        VkBool32 sharedImage;
    };

    struct VkShaderResourceUsageAMD {
        uint32_t numUsedVgprs;
        uint32_t numUsedSgprs;
        uint32_t ldsSizePerLocalWorkGroup;
        size_t ldsUsageSizeInBytes;
        size_t scratchMemUsageInBytes;
    };

    struct VkShaderStatisticsInfoAMD {
        VkShaderStageFlags shaderStageMask;
        VkShaderResourceUsageAMD resourceUsage;
        uint32_t numPhysicalVgprs;
        uint32_t numPhysicalSgprs;
        uint32_t numAvailableVgprs;
        uint32_t numAvailableSgprs;
        uint32_t computeWorkGroupSize[3];
    };

    struct VkDeviceQueueGlobalPriorityCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkQueueGlobalPriority globalPriority;
    };

    struct VkDeviceQueueGlobalPriorityCreateInfoKHR {
    };

    struct VkDeviceQueueGlobalPriorityCreateInfoEXT {
    };

    struct VkPhysicalDeviceGlobalPriorityQueryFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 globalPriorityQuery;
    };

    struct VkPhysicalDeviceGlobalPriorityQueryFeaturesKHR {
    };

    struct VkPhysicalDeviceGlobalPriorityQueryFeaturesEXT {
    };

    struct VkQueueFamilyGlobalPriorityProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t priorityCount;
        VkQueueGlobalPriority priorities[16];
    };

    struct VkQueueFamilyGlobalPriorityPropertiesKHR {
    };

    struct VkQueueFamilyGlobalPriorityPropertiesEXT {
    };

    struct VkDebugUtilsObjectNameInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkObjectType objectType;
        uint64_t objectHandle;
        const char* pObjectName;
    };

    struct VkDebugUtilsObjectTagInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkObjectType objectType;
        uint64_t objectHandle;
        uint64_t tagName;
        size_t tagSize;
        const void* pTag;
    };

    struct VkDebugUtilsLabelEXT {
        VkStructureType sType;
        const void* pNext;
        const char* pLabelName;
        float color[4];
    };

    struct VkDebugUtilsMessengerCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDebugUtilsMessengerCreateFlagsEXT flags;
        VkDebugUtilsMessageSeverityFlagsEXT messageSeverity;
        VkDebugUtilsMessageTypeFlagsEXT messageType;
        PFN_vkDebugUtilsMessengerCallbackEXT pfnUserCallback;
        void* pUserData;
    };

    struct VkDebugUtilsMessengerCallbackDataEXT {
        VkStructureType sType;
        const void* pNext;
        VkDebugUtilsMessengerCallbackDataFlagsEXT flags;
        const char* pMessageIdName;
        int32_t messageIdNumber;
        const char* pMessage;
        uint32_t queueLabelCount;
        const VkDebugUtilsLabelEXT* pQueueLabels;
        uint32_t cmdBufLabelCount;
        const VkDebugUtilsLabelEXT* pCmdBufLabels;
        uint32_t objectCount;
        const VkDebugUtilsObjectNameInfoEXT* pObjects;
    };

    struct VkPhysicalDeviceDeviceMemoryReportFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 deviceMemoryReport;
    };

    struct VkDeviceDeviceMemoryReportCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemoryReportFlagsEXT flags;
        PFN_vkDeviceMemoryReportCallbackEXT pfnUserCallback;
        void* pUserData;
    };

    struct VkDeviceMemoryReportCallbackDataEXT {
        VkStructureType sType;
        void* pNext;
        VkDeviceMemoryReportFlagsEXT flags;
        VkDeviceMemoryReportEventTypeEXT type;
        uint64_t memoryObjectId;
        VkDeviceSize size;
        VkObjectType objectType;
        uint64_t objectHandle;
        uint32_t heapIndex;
    };

    struct VkImportMemoryHostPointerInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlagBits handleType;
        void* pHostPointer;
    };

    struct VkMemoryHostPointerPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t memoryTypeBits;
    };

    struct VkPhysicalDeviceExternalMemoryHostPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize minImportedHostPointerAlignment;
    };

    struct VkPhysicalDeviceConservativeRasterizationPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        float primitiveOverestimationSize;
        float maxExtraPrimitiveOverestimationSize;
        float extraPrimitiveOverestimationSizeGranularity;
        VkBool32 primitiveUnderestimation;
        VkBool32 conservativePointAndLineRasterization;
        VkBool32 degenerateTrianglesRasterized;
        VkBool32 degenerateLinesRasterized;
        VkBool32 fullyCoveredFragmentShaderInputVariable;
        VkBool32 conservativeRasterizationPostDepthCoverage;
    };

    struct VkCalibratedTimestampInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkTimeDomainKHR timeDomain;
    };

    struct VkCalibratedTimestampInfoEXT {
    };

    struct VkPhysicalDeviceShaderCorePropertiesAMD {
        VkStructureType sType;
        void* pNext;
        uint32_t shaderEngineCount;
        uint32_t shaderArraysPerEngineCount;
        uint32_t computeUnitsPerShaderArray;
        uint32_t simdPerComputeUnit;
        uint32_t wavefrontsPerSimd;
        uint32_t wavefrontSize;
        uint32_t sgprsPerSimd;
        uint32_t minSgprAllocation;
        uint32_t maxSgprAllocation;
        uint32_t sgprAllocationGranularity;
        uint32_t vgprsPerSimd;
        uint32_t minVgprAllocation;
        uint32_t maxVgprAllocation;
        uint32_t vgprAllocationGranularity;
    };

    struct VkPhysicalDeviceShaderCoreProperties2AMD {
        VkStructureType sType;
        void* pNext;
        VkShaderCorePropertiesFlagsAMD shaderCoreFeatures;
        uint32_t activeComputeUnitCount;
    };

    struct VkPipelineRasterizationConservativeStateCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkPipelineRasterizationConservativeStateCreateFlagsEXT flags;
        VkConservativeRasterizationModeEXT conservativeRasterizationMode;
        float extraPrimitiveOverestimationSize;
    };

    struct VkPhysicalDeviceDescriptorIndexingFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderInputAttachmentArrayDynamicIndexing;
        VkBool32 shaderUniformTexelBufferArrayDynamicIndexing;
        VkBool32 shaderStorageTexelBufferArrayDynamicIndexing;
        VkBool32 shaderUniformBufferArrayNonUniformIndexing;
        VkBool32 shaderSampledImageArrayNonUniformIndexing;
        VkBool32 shaderStorageBufferArrayNonUniformIndexing;
        VkBool32 shaderStorageImageArrayNonUniformIndexing;
        VkBool32 shaderInputAttachmentArrayNonUniformIndexing;
        VkBool32 shaderUniformTexelBufferArrayNonUniformIndexing;
        VkBool32 shaderStorageTexelBufferArrayNonUniformIndexing;
        VkBool32 descriptorBindingUniformBufferUpdateAfterBind;
        VkBool32 descriptorBindingSampledImageUpdateAfterBind;
        VkBool32 descriptorBindingStorageImageUpdateAfterBind;
        VkBool32 descriptorBindingStorageBufferUpdateAfterBind;
        VkBool32 descriptorBindingUniformTexelBufferUpdateAfterBind;
        VkBool32 descriptorBindingStorageTexelBufferUpdateAfterBind;
        VkBool32 descriptorBindingUpdateUnusedWhilePending;
        VkBool32 descriptorBindingPartiallyBound;
        VkBool32 descriptorBindingVariableDescriptorCount;
        VkBool32 runtimeDescriptorArray;
    };

    struct VkPhysicalDeviceDescriptorIndexingFeaturesEXT {
    };

    struct VkPhysicalDeviceDescriptorIndexingProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t maxUpdateAfterBindDescriptorsInAllPools;
        VkBool32 shaderUniformBufferArrayNonUniformIndexingNative;
        VkBool32 shaderSampledImageArrayNonUniformIndexingNative;
        VkBool32 shaderStorageBufferArrayNonUniformIndexingNative;
        VkBool32 shaderStorageImageArrayNonUniformIndexingNative;
        VkBool32 shaderInputAttachmentArrayNonUniformIndexingNative;
        VkBool32 robustBufferAccessUpdateAfterBind;
        VkBool32 quadDivergentImplicitLod;
        uint32_t maxPerStageDescriptorUpdateAfterBindSamplers;
        uint32_t maxPerStageDescriptorUpdateAfterBindUniformBuffers;
        uint32_t maxPerStageDescriptorUpdateAfterBindStorageBuffers;
        uint32_t maxPerStageDescriptorUpdateAfterBindSampledImages;
        uint32_t maxPerStageDescriptorUpdateAfterBindStorageImages;
        uint32_t maxPerStageDescriptorUpdateAfterBindInputAttachments;
        uint32_t maxPerStageUpdateAfterBindResources;
        uint32_t maxDescriptorSetUpdateAfterBindSamplers;
        uint32_t maxDescriptorSetUpdateAfterBindUniformBuffers;
        uint32_t maxDescriptorSetUpdateAfterBindUniformBuffersDynamic;
        uint32_t maxDescriptorSetUpdateAfterBindStorageBuffers;
        uint32_t maxDescriptorSetUpdateAfterBindStorageBuffersDynamic;
        uint32_t maxDescriptorSetUpdateAfterBindSampledImages;
        uint32_t maxDescriptorSetUpdateAfterBindStorageImages;
        uint32_t maxDescriptorSetUpdateAfterBindInputAttachments;
    };

    struct VkPhysicalDeviceDescriptorIndexingPropertiesEXT {
    };

    struct VkDescriptorSetLayoutBindingFlagsCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t bindingCount;
        const VkDescriptorBindingFlags* pBindingFlags;
    };

    struct VkDescriptorSetLayoutBindingFlagsCreateInfoEXT {
    };

    struct VkDescriptorSetVariableDescriptorCountAllocateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t descriptorSetCount;
        const uint32_t* pDescriptorCounts;
    };

    struct VkDescriptorSetVariableDescriptorCountAllocateInfoEXT {
    };

    struct VkDescriptorSetVariableDescriptorCountLayoutSupport {
        VkStructureType sType;
        void* pNext;
        uint32_t maxVariableDescriptorCount;
    };

    struct VkDescriptorSetVariableDescriptorCountLayoutSupportEXT {
    };

    struct VkAttachmentDescription2 {
        VkStructureType sType;
        const void* pNext;
        VkAttachmentDescriptionFlags flags;
        VkFormat format;
        VkSampleCountFlagBits samples;
        VkAttachmentLoadOp loadOp;
        VkAttachmentStoreOp storeOp;
        VkAttachmentLoadOp stencilLoadOp;
        VkAttachmentStoreOp stencilStoreOp;
        VkImageLayout initialLayout;
        VkImageLayout finalLayout;
    };

    struct VkAttachmentDescription2KHR {
    };

    struct VkAttachmentReference2 {
        VkStructureType sType;
        const void* pNext;
        uint32_t attachment;
        VkImageLayout layout;
        VkImageAspectFlags aspectMask;
    };

    struct VkAttachmentReference2KHR {
    };

    struct VkSubpassDescription2 {
        VkStructureType sType;
        const void* pNext;
        VkSubpassDescriptionFlags flags;
        VkPipelineBindPoint pipelineBindPoint;
        uint32_t viewMask;
        uint32_t inputAttachmentCount;
        const VkAttachmentReference2* pInputAttachments;
        uint32_t colorAttachmentCount;
        const VkAttachmentReference2* pColorAttachments;
        const VkAttachmentReference2* pResolveAttachments;
        const VkAttachmentReference2* pDepthStencilAttachment;
        uint32_t preserveAttachmentCount;
        const uint32_t* pPreserveAttachments;
    };

    struct VkSubpassDescription2KHR {
    };

    struct VkSubpassDependency2 {
        VkStructureType sType;
        const void* pNext;
        uint32_t srcSubpass;
        uint32_t dstSubpass;
        VkPipelineStageFlags srcStageMask;
        VkPipelineStageFlags dstStageMask;
        VkAccessFlags srcAccessMask;
        VkAccessFlags dstAccessMask;
        VkDependencyFlags dependencyFlags;
        int32_t viewOffset;
    };

    struct VkSubpassDependency2KHR {
    };

    struct VkRenderPassCreateInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkRenderPassCreateFlags flags;
        uint32_t attachmentCount;
        const VkAttachmentDescription2* pAttachments;
        uint32_t subpassCount;
        const VkSubpassDescription2* pSubpasses;
        uint32_t dependencyCount;
        const VkSubpassDependency2* pDependencies;
        uint32_t correlatedViewMaskCount;
        const uint32_t* pCorrelatedViewMasks;
    };

    struct VkRenderPassCreateInfo2KHR {
    };

    struct VkSubpassBeginInfo {
        VkStructureType sType;
        const void* pNext;
        VkSubpassContents contents;
    };

    struct VkSubpassBeginInfoKHR {
    };

    struct VkSubpassEndInfo {
        VkStructureType sType;
        const void* pNext;
    };

    struct VkSubpassEndInfoKHR {
    };

    struct VkPhysicalDeviceTimelineSemaphoreFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 timelineSemaphore;
    };

    struct VkPhysicalDeviceTimelineSemaphoreFeaturesKHR {
    };

    struct VkPhysicalDeviceTimelineSemaphoreProperties {
        VkStructureType sType;
        void* pNext;
        uint64_t maxTimelineSemaphoreValueDifference;
    };

    struct VkPhysicalDeviceTimelineSemaphorePropertiesKHR {
    };

    struct VkSemaphoreTypeCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkSemaphoreType semaphoreType;
        uint64_t initialValue;
    };

    struct VkSemaphoreTypeCreateInfoKHR {
    };

    struct VkTimelineSemaphoreSubmitInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t waitSemaphoreValueCount;
        const uint64_t* pWaitSemaphoreValues;
        uint32_t signalSemaphoreValueCount;
        const uint64_t* pSignalSemaphoreValues;
    };

    struct VkTimelineSemaphoreSubmitInfoKHR {
    };

    struct VkSemaphoreWaitInfo {
        VkStructureType sType;
        const void* pNext;
        VkSemaphoreWaitFlags flags;
        uint32_t semaphoreCount;
        const VkSemaphore* pSemaphores;
        const uint64_t* pValues;
    };

    struct VkSemaphoreWaitInfoKHR {
    };

    struct VkSemaphoreSignalInfo {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore semaphore;
        uint64_t value;
    };

    struct VkSemaphoreSignalInfoKHR {
    };

    struct VkVertexInputBindingDivisorDescription {
        uint32_t binding;
        uint32_t divisor;
    };

    struct VkVertexInputBindingDivisorDescriptionKHR {
    };

    struct VkVertexInputBindingDivisorDescriptionEXT {
    };

    struct VkPipelineVertexInputDivisorStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t vertexBindingDivisorCount;
        const VkVertexInputBindingDivisorDescription* pVertexBindingDivisors;
    };

    struct VkPipelineVertexInputDivisorStateCreateInfoKHR {
    };

    struct VkPipelineVertexInputDivisorStateCreateInfoEXT {
    };

    struct VkPhysicalDeviceVertexAttributeDivisorPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t maxVertexAttribDivisor;
    };

    struct VkPhysicalDeviceVertexAttributeDivisorProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t maxVertexAttribDivisor;
        VkBool32 supportsNonZeroFirstInstance;
    };

    struct VkPhysicalDeviceVertexAttributeDivisorPropertiesKHR {
    };

    struct VkPhysicalDevicePCIBusInfoPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t pciDomain;
        uint32_t pciBus;
        uint32_t pciDevice;
        uint32_t pciFunction;
    };

    struct VkImportAndroidHardwareBufferInfoANDROID {
        VkStructureType sType;
        const void* pNext;
        struct AHardwareBuffer* buffer;
    };

    struct VkAndroidHardwareBufferUsageANDROID {
        VkStructureType sType;
        void* pNext;
        uint64_t androidHardwareBufferUsage;
    };

    struct VkAndroidHardwareBufferPropertiesANDROID {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize allocationSize;
        uint32_t memoryTypeBits;
    };

    struct VkMemoryGetAndroidHardwareBufferInfoANDROID {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
    };

    struct VkAndroidHardwareBufferFormatPropertiesANDROID {
        VkStructureType sType;
        void* pNext;
        VkFormat format;
        uint64_t externalFormat;
        VkFormatFeatureFlags formatFeatures;
        VkComponentMapping samplerYcbcrConversionComponents;
        VkSamplerYcbcrModelConversion suggestedYcbcrModel;
        VkSamplerYcbcrRange suggestedYcbcrRange;
        VkChromaLocation suggestedXChromaOffset;
        VkChromaLocation suggestedYChromaOffset;
    };

    struct VkCommandBufferInheritanceConditionalRenderingInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkBool32 conditionalRenderingEnable;
    };

    struct VkExternalFormatANDROID {
        VkStructureType sType;
        void* pNext;
        uint64_t externalFormat;
    };

    struct VkPhysicalDevice8BitStorageFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 storageBuffer8BitAccess;
        VkBool32 uniformAndStorageBuffer8BitAccess;
        VkBool32 storagePushConstant8;
    };

    struct VkPhysicalDevice8BitStorageFeaturesKHR {
    };

    struct VkPhysicalDeviceConditionalRenderingFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 conditionalRendering;
        VkBool32 inheritedConditionalRendering;
    };

    struct VkPhysicalDeviceVulkanMemoryModelFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 vulkanMemoryModel;
        VkBool32 vulkanMemoryModelDeviceScope;
        VkBool32 vulkanMemoryModelAvailabilityVisibilityChains;
    };

    struct VkPhysicalDeviceVulkanMemoryModelFeaturesKHR {
    };

    struct VkPhysicalDeviceShaderAtomicInt64Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderBufferInt64Atomics;
        VkBool32 shaderSharedInt64Atomics;
    };

    struct VkPhysicalDeviceShaderAtomicInt64FeaturesKHR {
    };

    struct VkPhysicalDeviceShaderAtomicFloatFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderBufferFloat32Atomics;
        VkBool32 shaderBufferFloat32AtomicAdd;
        VkBool32 shaderBufferFloat64Atomics;
        VkBool32 shaderBufferFloat64AtomicAdd;
        VkBool32 shaderSharedFloat32Atomics;
        VkBool32 shaderSharedFloat32AtomicAdd;
        VkBool32 shaderSharedFloat64Atomics;
        VkBool32 shaderSharedFloat64AtomicAdd;
        VkBool32 shaderImageFloat32Atomics;
        VkBool32 shaderImageFloat32AtomicAdd;
        VkBool32 sparseImageFloat32Atomics;
        VkBool32 sparseImageFloat32AtomicAdd;
    };

    struct VkPhysicalDeviceShaderAtomicFloat2FeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderBufferFloat16Atomics;
        VkBool32 shaderBufferFloat16AtomicAdd;
        VkBool32 shaderBufferFloat16AtomicMinMax;
        VkBool32 shaderBufferFloat32AtomicMinMax;
        VkBool32 shaderBufferFloat64AtomicMinMax;
        VkBool32 shaderSharedFloat16Atomics;
        VkBool32 shaderSharedFloat16AtomicAdd;
        VkBool32 shaderSharedFloat16AtomicMinMax;
        VkBool32 shaderSharedFloat32AtomicMinMax;
        VkBool32 shaderSharedFloat64AtomicMinMax;
        VkBool32 shaderImageFloat32AtomicMinMax;
        VkBool32 sparseImageFloat32AtomicMinMax;
    };

    struct VkPhysicalDeviceVertexAttributeDivisorFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 vertexAttributeInstanceRateDivisor;
        VkBool32 vertexAttributeInstanceRateZeroDivisor;
    };

    struct VkPhysicalDeviceVertexAttributeDivisorFeaturesKHR {
    };

    struct VkPhysicalDeviceVertexAttributeDivisorFeaturesEXT {
    };

    struct VkQueueFamilyCheckpointPropertiesNV {
        VkStructureType sType;
        void* pNext;
        VkPipelineStageFlags checkpointExecutionStageMask;
    };

    struct VkCheckpointDataNV {
        VkStructureType sType;
        void* pNext;
        VkPipelineStageFlagBits stage;
        void* pCheckpointMarker;
    };

    struct VkPhysicalDeviceDepthStencilResolveProperties {
        VkStructureType sType;
        void* pNext;
        VkResolveModeFlags supportedDepthResolveModes;
        VkResolveModeFlags supportedStencilResolveModes;
        VkBool32 independentResolveNone;
        VkBool32 independentResolve;
    };

    struct VkPhysicalDeviceDepthStencilResolvePropertiesKHR {
    };

    struct VkSubpassDescriptionDepthStencilResolve {
        VkStructureType sType;
        const void* pNext;
        VkResolveModeFlagBits depthResolveMode;
        VkResolveModeFlagBits stencilResolveMode;
        const VkAttachmentReference2* pDepthStencilResolveAttachment;
    };

    struct VkSubpassDescriptionDepthStencilResolveKHR {
    };

    struct VkImageViewASTCDecodeModeEXT {
        VkStructureType sType;
        const void* pNext;
        VkFormat decodeMode;
    };

    struct VkPhysicalDeviceASTCDecodeFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 decodeModeSharedExponent;
    };

    struct VkPhysicalDeviceTransformFeedbackFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 transformFeedback;
        VkBool32 geometryStreams;
    };

    struct VkPhysicalDeviceTransformFeedbackPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t maxTransformFeedbackStreams;
        uint32_t maxTransformFeedbackBuffers;
        VkDeviceSize maxTransformFeedbackBufferSize;
        uint32_t maxTransformFeedbackStreamDataSize;
        uint32_t maxTransformFeedbackBufferDataSize;
        uint32_t maxTransformFeedbackBufferDataStride;
        VkBool32 transformFeedbackQueries;
        VkBool32 transformFeedbackStreamsLinesTriangles;
        VkBool32 transformFeedbackRasterizationStreamSelect;
        VkBool32 transformFeedbackDraw;
    };

    struct VkPipelineRasterizationStateStreamCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkPipelineRasterizationStateStreamCreateFlagsEXT flags;
        uint32_t rasterizationStream;
    };

    struct VkPhysicalDeviceRepresentativeFragmentTestFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 representativeFragmentTest;
    };

    struct VkPipelineRepresentativeFragmentTestStateCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkBool32 representativeFragmentTestEnable;
    };

    struct VkPhysicalDeviceExclusiveScissorFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 exclusiveScissor;
    };

    struct VkPipelineViewportExclusiveScissorStateCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t exclusiveScissorCount;
        const VkRect2D* pExclusiveScissors;
    };

    struct VkPhysicalDeviceCornerSampledImageFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 cornerSampledImage;
    };

    struct VkPhysicalDeviceComputeShaderDerivativesFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 computeDerivativeGroupQuads;
        VkBool32 computeDerivativeGroupLinear;
    };

    struct VkPhysicalDeviceComputeShaderDerivativesFeaturesNV {
    };

    struct VkPhysicalDeviceComputeShaderDerivativesPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 meshAndTaskShaderDerivatives;
    };

    struct VkPhysicalDeviceFragmentShaderBarycentricFeaturesNV {
    };

    struct VkPhysicalDeviceShaderImageFootprintFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 imageFootprint;
    };

    struct VkPhysicalDeviceDedicatedAllocationImageAliasingFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 dedicatedAllocationImageAliasing;
    };

    struct VkPhysicalDeviceCopyMemoryIndirectFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 indirectMemoryCopy;
        VkBool32 indirectMemoryToImageCopy;
    };

    struct VkPhysicalDeviceCopyMemoryIndirectFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 indirectCopy;
    };

    struct VkPhysicalDeviceCopyMemoryIndirectPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkQueueFlags supportedQueues;
    };

    struct VkPhysicalDeviceCopyMemoryIndirectPropertiesNV {
    };

    struct VkPhysicalDeviceMemoryDecompressionFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 memoryDecompression;
    };

    struct VkPhysicalDeviceMemoryDecompressionFeaturesNV {
    };

    struct VkPhysicalDeviceMemoryDecompressionPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkMemoryDecompressionMethodFlagsEXT decompressionMethods;
        uint64_t maxDecompressionIndirectCount;
    };

    struct VkPhysicalDeviceMemoryDecompressionPropertiesNV {
    };

    struct VkShadingRatePaletteNV {
        uint32_t shadingRatePaletteEntryCount;
        const VkShadingRatePaletteEntryNV* pShadingRatePaletteEntries;
    };

    struct VkPipelineViewportShadingRateImageStateCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkBool32 shadingRateImageEnable;
        uint32_t viewportCount;
        const VkShadingRatePaletteNV* pShadingRatePalettes;
    };

    struct VkPhysicalDeviceShadingRateImageFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 shadingRateImage;
        VkBool32 shadingRateCoarseSampleOrder;
    };

    struct VkPhysicalDeviceShadingRateImagePropertiesNV {
        VkStructureType sType;
        void* pNext;
        VkExtent2D shadingRateTexelSize;
        uint32_t shadingRatePaletteSize;
        uint32_t shadingRateMaxCoarseSamples;
    };

    struct VkPhysicalDeviceInvocationMaskFeaturesHUAWEI {
        VkStructureType sType;
        void* pNext;
        VkBool32 invocationMask;
    };

    struct VkCoarseSampleLocationNV {
        uint32_t pixelX;
        uint32_t pixelY;
        uint32_t sample;
    };

    struct VkCoarseSampleOrderCustomNV {
        VkShadingRatePaletteEntryNV shadingRate;
        uint32_t sampleCount;
        uint32_t sampleLocationCount;
        const VkCoarseSampleLocationNV* pSampleLocations;
    };

    struct VkPipelineViewportCoarseSampleOrderStateCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkCoarseSampleOrderTypeNV sampleOrderType;
        uint32_t customSampleOrderCount;
        const VkCoarseSampleOrderCustomNV* pCustomSampleOrders;
    };

    struct VkPhysicalDeviceMeshShaderFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 taskShader;
        VkBool32 meshShader;
    };

    struct VkPhysicalDeviceMeshShaderPropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t maxDrawMeshTasksCount;
        uint32_t maxTaskWorkGroupInvocations;
        uint32_t maxTaskWorkGroupSize[3];
        uint32_t maxTaskTotalMemorySize;
        uint32_t maxTaskOutputCount;
        uint32_t maxMeshWorkGroupInvocations;
        uint32_t maxMeshWorkGroupSize[3];
        uint32_t maxMeshTotalMemorySize;
        uint32_t maxMeshOutputVertices;
        uint32_t maxMeshOutputPrimitives;
        uint32_t maxMeshMultiviewViewCount;
        uint32_t meshOutputPerVertexGranularity;
        uint32_t meshOutputPerPrimitiveGranularity;
    };

    struct VkDrawMeshTasksIndirectCommandNV {
        uint32_t taskCount;
        uint32_t firstTask;
    };

    struct VkPhysicalDeviceMeshShaderFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 taskShader;
        VkBool32 meshShader;
        VkBool32 multiviewMeshShader;
        VkBool32 primitiveFragmentShadingRateMeshShader;
        VkBool32 meshShaderQueries;
    };

    struct VkPhysicalDeviceMeshShaderPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t maxTaskWorkGroupTotalCount;
        uint32_t maxTaskWorkGroupCount[3];
        uint32_t maxTaskWorkGroupInvocations;
        uint32_t maxTaskWorkGroupSize[3];
        uint32_t maxTaskPayloadSize;
        uint32_t maxTaskSharedMemorySize;
        uint32_t maxTaskPayloadAndSharedMemorySize;
        uint32_t maxMeshWorkGroupTotalCount;
        uint32_t maxMeshWorkGroupCount[3];
        uint32_t maxMeshWorkGroupInvocations;
        uint32_t maxMeshWorkGroupSize[3];
        uint32_t maxMeshSharedMemorySize;
        uint32_t maxMeshPayloadAndSharedMemorySize;
        uint32_t maxMeshOutputMemorySize;
        uint32_t maxMeshPayloadAndOutputMemorySize;
        uint32_t maxMeshOutputComponents;
        uint32_t maxMeshOutputVertices;
        uint32_t maxMeshOutputPrimitives;
        uint32_t maxMeshOutputLayers;
        uint32_t maxMeshMultiviewViewCount;
        uint32_t meshOutputPerVertexGranularity;
        uint32_t meshOutputPerPrimitiveGranularity;
        uint32_t maxPreferredTaskWorkGroupInvocations;
        uint32_t maxPreferredMeshWorkGroupInvocations;
        VkBool32 prefersLocalInvocationVertexOutput;
        VkBool32 prefersLocalInvocationPrimitiveOutput;
        VkBool32 prefersCompactVertexOutput;
        VkBool32 prefersCompactPrimitiveOutput;
    };

    struct VkDrawMeshTasksIndirectCommandEXT {
        uint32_t groupCountX;
        uint32_t groupCountY;
        uint32_t groupCountZ;
    };

    struct VkRayTracingShaderGroupCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkRayTracingShaderGroupTypeKHR type;
        uint32_t generalShader;
        uint32_t closestHitShader;
        uint32_t anyHitShader;
        uint32_t intersectionShader;
    };

    struct VkRayTracingShaderGroupCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkRayTracingShaderGroupTypeKHR type;
        uint32_t generalShader;
        uint32_t closestHitShader;
        uint32_t anyHitShader;
        uint32_t intersectionShader;
        const void* pShaderGroupCaptureReplayHandle;
    };

    struct VkRayTracingPipelineCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCreateFlags flags;
        uint32_t stageCount;
        const VkPipelineShaderStageCreateInfo* pStages;
        uint32_t groupCount;
        const VkRayTracingShaderGroupCreateInfoNV* pGroups;
        uint32_t maxRecursionDepth;
        VkPipelineLayout layout;
        VkPipeline basePipelineHandle;
        int32_t basePipelineIndex;
    };

    struct VkRayTracingPipelineCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCreateFlags flags;
        uint32_t stageCount;
        const VkPipelineShaderStageCreateInfo* pStages;
        uint32_t groupCount;
        const VkRayTracingShaderGroupCreateInfoKHR* pGroups;
        uint32_t maxPipelineRayRecursionDepth;
        const VkPipelineLibraryCreateInfoKHR* pLibraryInfo;
        const VkRayTracingPipelineInterfaceCreateInfoKHR* pLibraryInterface;
        const VkPipelineDynamicStateCreateInfo* pDynamicState;
        VkPipelineLayout layout;
        VkPipeline basePipelineHandle;
        int32_t basePipelineIndex;
    };

    struct VkGeometryTrianglesNV {
        VkStructureType sType;
        const void* pNext;
        VkBuffer vertexData;
        VkDeviceSize vertexOffset;
        uint32_t vertexCount;
        VkDeviceSize vertexStride;
        VkFormat vertexFormat;
        VkBuffer indexData;
        VkDeviceSize indexOffset;
        uint32_t indexCount;
        VkIndexType indexType;
        VkBuffer transformData;
        VkDeviceSize transformOffset;
    };

    struct VkGeometryAABBNV {
        VkStructureType sType;
        const void* pNext;
        VkBuffer aabbData;
        uint32_t numAABBs;
        uint32_t stride;
        VkDeviceSize offset;
    };

    struct VkGeometryDataNV {
        VkGeometryTrianglesNV triangles;
        VkGeometryAABBNV aabbs;
    };

    struct VkGeometryNV {
        VkStructureType sType;
        const void* pNext;
        VkGeometryTypeKHR geometryType;
        VkGeometryDataNV geometry;
        VkGeometryFlagsKHR flags;
    };

    struct VkAccelerationStructureInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkAccelerationStructureTypeNV type;
        VkBuildAccelerationStructureFlagsNV flags;
        uint32_t instanceCount;
        uint32_t geometryCount;
        const VkGeometryNV* pGeometries;
    };

    struct VkAccelerationStructureCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkDeviceSize compactedSize;
        VkAccelerationStructureInfoNV info;
    };

    struct VkBindAccelerationStructureMemoryInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkAccelerationStructureNV accelerationStructure;
        VkDeviceMemory memory;
        VkDeviceSize memoryOffset;
        uint32_t deviceIndexCount;
        const uint32_t* pDeviceIndices;
    };

    struct VkWriteDescriptorSetAccelerationStructureKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t accelerationStructureCount;
        const VkAccelerationStructureKHR* pAccelerationStructures;
    };

    struct VkWriteDescriptorSetAccelerationStructureNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t accelerationStructureCount;
        const VkAccelerationStructureNV* pAccelerationStructures;
    };

    struct VkAccelerationStructureMemoryRequirementsInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkAccelerationStructureMemoryRequirementsTypeNV type;
        VkAccelerationStructureNV accelerationStructure;
    };

    struct VkPhysicalDeviceAccelerationStructureFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 accelerationStructure;
        VkBool32 accelerationStructureCaptureReplay;
        VkBool32 accelerationStructureIndirectBuild;
        VkBool32 accelerationStructureHostCommands;
        VkBool32 descriptorBindingAccelerationStructureUpdateAfterBind;
    };

    struct VkPhysicalDeviceRayTracingPipelineFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 rayTracingPipeline;
        VkBool32 rayTracingPipelineShaderGroupHandleCaptureReplay;
        VkBool32 rayTracingPipelineShaderGroupHandleCaptureReplayMixed;
        VkBool32 rayTracingPipelineTraceRaysIndirect;
        VkBool32 rayTraversalPrimitiveCulling;
    };

    struct VkPhysicalDeviceRayQueryFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 rayQuery;
    };

    struct VkPhysicalDeviceAccelerationStructurePropertiesKHR {
        VkStructureType sType;
        void* pNext;
        uint64_t maxGeometryCount;
        uint64_t maxInstanceCount;
        uint64_t maxPrimitiveCount;
        uint32_t maxPerStageDescriptorAccelerationStructures;
        uint32_t maxPerStageDescriptorUpdateAfterBindAccelerationStructures;
        uint32_t maxDescriptorSetAccelerationStructures;
        uint32_t maxDescriptorSetUpdateAfterBindAccelerationStructures;
        uint32_t minAccelerationStructureScratchOffsetAlignment;
    };

    struct VkPhysicalDeviceRayTracingPipelinePropertiesKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t shaderGroupHandleSize;
        uint32_t maxRayRecursionDepth;
        uint32_t maxShaderGroupStride;
        uint32_t shaderGroupBaseAlignment;
        uint32_t shaderGroupHandleCaptureReplaySize;
        uint32_t maxRayDispatchInvocationCount;
        uint32_t shaderGroupHandleAlignment;
        uint32_t maxRayHitAttributeSize;
    };

    struct VkPhysicalDeviceRayTracingPropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t shaderGroupHandleSize;
        uint32_t maxRecursionDepth;
        uint32_t maxShaderGroupStride;
        uint32_t shaderGroupBaseAlignment;
        uint64_t maxGeometryCount;
        uint64_t maxInstanceCount;
        uint64_t maxTriangleCount;
        uint32_t maxDescriptorSetAccelerationStructures;
    };

    struct VkTraceRaysIndirectCommandKHR {
        uint32_t width;
        uint32_t height;
        uint32_t depth;
    };

    struct VkTraceRaysIndirectCommand2KHR {
        VkDeviceAddress raygenShaderRecordAddress;
        VkDeviceSize raygenShaderRecordSize;
        VkDeviceAddress missShaderBindingTableAddress;
        VkDeviceSize missShaderBindingTableSize;
        VkDeviceSize missShaderBindingTableStride;
        VkDeviceAddress hitShaderBindingTableAddress;
        VkDeviceSize hitShaderBindingTableSize;
        VkDeviceSize hitShaderBindingTableStride;
        VkDeviceAddress callableShaderBindingTableAddress;
        VkDeviceSize callableShaderBindingTableSize;
        VkDeviceSize callableShaderBindingTableStride;
        uint32_t width;
        uint32_t height;
        uint32_t depth;
    };

    struct VkPhysicalDeviceRayTracingMaintenance1FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 rayTracingMaintenance1;
        VkBool32 rayTracingPipelineTraceRaysIndirect2;
    };

    struct VkDrmFormatModifierPropertiesListEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t drmFormatModifierCount;
        VkDrmFormatModifierPropertiesEXT* pDrmFormatModifierProperties;
    };

    struct VkDrmFormatModifierPropertiesEXT {
        uint64_t drmFormatModifier;
        uint32_t drmFormatModifierPlaneCount;
        VkFormatFeatureFlags drmFormatModifierTilingFeatures;
    };

    struct VkPhysicalDeviceImageDrmFormatModifierInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint64_t drmFormatModifier;
        VkSharingMode sharingMode;
        uint32_t queueFamilyIndexCount;
        const uint32_t* pQueueFamilyIndices;
    };

    struct VkImageDrmFormatModifierListCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t drmFormatModifierCount;
        const uint64_t* pDrmFormatModifiers;
    };

    struct VkImageDrmFormatModifierExplicitCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint64_t drmFormatModifier;
        uint32_t drmFormatModifierPlaneCount;
        const VkSubresourceLayout* pPlaneLayouts;
    };

    struct VkImageDrmFormatModifierPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint64_t drmFormatModifier;
    };

    struct VkImageStencilUsageCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkImageUsageFlags stencilUsage;
    };

    struct VkImageStencilUsageCreateInfoEXT {
    };

    struct VkDeviceMemoryOverallocationCreateInfoAMD {
        VkStructureType sType;
        const void* pNext;
        VkMemoryOverallocationBehaviorAMD overallocationBehavior;
    };

    struct VkPhysicalDeviceFragmentDensityMapFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 fragmentDensityMap;
        VkBool32 fragmentDensityMapDynamic;
        VkBool32 fragmentDensityMapNonSubsampledImages;
    };

    struct VkPhysicalDeviceFragmentDensityMap2FeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 fragmentDensityMapDeferred;
    };

    struct VkPhysicalDeviceFragmentDensityMapOffsetFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 fragmentDensityMapOffset;
    };

    struct VkPhysicalDeviceFragmentDensityMapOffsetFeaturesQCOM {
    };

    struct VkPhysicalDeviceFragmentDensityMapPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkExtent2D minFragmentDensityTexelSize;
        VkExtent2D maxFragmentDensityTexelSize;
        VkBool32 fragmentDensityInvocations;
    };

    struct VkPhysicalDeviceFragmentDensityMap2PropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 subsampledLoads;
        VkBool32 subsampledCoarseReconstructionEarlyAccess;
        uint32_t maxSubsampledArrayLayers;
        uint32_t maxDescriptorSetSubsampledSamplers;
    };

    struct VkPhysicalDeviceFragmentDensityMapOffsetPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkExtent2D fragmentDensityOffsetGranularity;
    };

    struct VkPhysicalDeviceFragmentDensityMapOffsetPropertiesQCOM {
    };

    struct VkRenderPassFragmentDensityMapCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkAttachmentReference fragmentDensityMapAttachment;
    };

    struct VkRenderPassFragmentDensityMapOffsetEndInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t fragmentDensityOffsetCount;
        const VkOffset2D* pFragmentDensityOffsets;
    };

    struct VkSubpassFragmentDensityMapOffsetEndInfoQCOM {
    };

    struct VkPhysicalDeviceScalarBlockLayoutFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 scalarBlockLayout;
    };

    struct VkPhysicalDeviceScalarBlockLayoutFeaturesEXT {
    };

    struct VkSurfaceProtectedCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 supportsProtected;
    };

    struct VkPhysicalDeviceUniformBufferStandardLayoutFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 uniformBufferStandardLayout;
    };

    struct VkPhysicalDeviceUniformBufferStandardLayoutFeaturesKHR {
    };

    struct VkPhysicalDeviceDepthClipEnableFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 depthClipEnable;
    };

    struct VkPipelineRasterizationDepthClipStateCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkPipelineRasterizationDepthClipStateCreateFlagsEXT flags;
        VkBool32 depthClipEnable;
    };

    struct VkPhysicalDeviceMemoryBudgetPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize heapBudget[16];
        VkDeviceSize heapUsage[16];
    };

    struct VkPhysicalDeviceMemoryPriorityFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 memoryPriority;
    };

    struct VkMemoryPriorityAllocateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        float priority;
    };

    struct VkPhysicalDevicePageableDeviceLocalMemoryFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 pageableDeviceLocalMemory;
    };

    struct VkPhysicalDeviceBufferDeviceAddressFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 bufferDeviceAddress;
        VkBool32 bufferDeviceAddressCaptureReplay;
        VkBool32 bufferDeviceAddressMultiDevice;
    };

    struct VkPhysicalDeviceBufferDeviceAddressFeaturesKHR {
    };

    struct VkPhysicalDeviceBufferDeviceAddressFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 bufferDeviceAddress;
        VkBool32 bufferDeviceAddressCaptureReplay;
        VkBool32 bufferDeviceAddressMultiDevice;
    };

    struct VkPhysicalDeviceBufferAddressFeaturesEXT {
    };

    struct VkBufferDeviceAddressInfo {
        VkStructureType sType;
        const void* pNext;
        VkBuffer buffer;
    };

    struct VkBufferDeviceAddressInfoKHR {
    };

    struct VkBufferDeviceAddressInfoEXT {
    };

    struct VkBufferOpaqueCaptureAddressCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint64_t opaqueCaptureAddress;
    };

    struct VkBufferOpaqueCaptureAddressCreateInfoKHR {
    };

    struct VkBufferDeviceAddressCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDeviceAddress deviceAddress;
    };

    struct VkPhysicalDeviceImageViewImageFormatInfoEXT {
        VkStructureType sType;
        void* pNext;
        VkImageViewType imageViewType;
    };

    struct VkFilterCubicImageViewImageFormatPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 filterCubic;
        VkBool32 filterCubicMinmax;
    };

    struct VkPhysicalDeviceImagelessFramebufferFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 imagelessFramebuffer;
    };

    struct VkPhysicalDeviceImagelessFramebufferFeaturesKHR {
    };

    struct VkFramebufferAttachmentsCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t attachmentImageInfoCount;
        const VkFramebufferAttachmentImageInfo* pAttachmentImageInfos;
    };

    struct VkFramebufferAttachmentsCreateInfoKHR {
    };

    struct VkFramebufferAttachmentImageInfo {
        VkStructureType sType;
        const void* pNext;
        VkImageCreateFlags flags;
        VkImageUsageFlags usage;
        uint32_t width;
        uint32_t height;
        uint32_t layerCount;
        uint32_t viewFormatCount;
        const VkFormat* pViewFormats;
    };

    struct VkFramebufferAttachmentImageInfoKHR {
    };

    struct VkRenderPassAttachmentBeginInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t attachmentCount;
        const VkImageView* pAttachments;
    };

    struct VkRenderPassAttachmentBeginInfoKHR {
    };

    struct VkPhysicalDeviceTextureCompressionASTCHDRFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 textureCompressionASTC_HDR;
    };

    struct VkPhysicalDeviceTextureCompressionASTCHDRFeaturesEXT {
    };

    struct VkPhysicalDeviceCooperativeMatrixFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 cooperativeMatrix;
        VkBool32 cooperativeMatrixRobustBufferAccess;
    };

    struct VkPhysicalDeviceCooperativeMatrixPropertiesNV {
        VkStructureType sType;
        void* pNext;
        VkShaderStageFlags cooperativeMatrixSupportedStages;
    };

    struct VkCooperativeMatrixPropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t MSize;
        uint32_t NSize;
        uint32_t KSize;
        VkComponentTypeNV AType;
        VkComponentTypeNV BType;
        VkComponentTypeNV CType;
        VkComponentTypeNV DType;
        VkScopeNV scope;
    };

    struct VkPhysicalDeviceYcbcrImageArraysFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 ycbcrImageArrays;
    };

    struct VkImageViewHandleInfoNVX {
        VkStructureType sType;
        const void* pNext;
        VkImageView imageView;
        VkDescriptorType descriptorType;
        VkSampler sampler;
    };

    struct VkImageViewAddressPropertiesNVX {
        VkStructureType sType;
        void* pNext;
        VkDeviceAddress deviceAddress;
        VkDeviceSize size;
    };

    struct VkPresentFrameTokenGGP {
        VkStructureType sType;
        const void* pNext;
        GgpFrameToken frameToken;
    };

    struct VkPipelineCreationFeedback {
        VkPipelineCreationFeedbackFlags flags;
        uint64_t duration;
    };

    struct VkPipelineCreationFeedbackEXT {
    };

    struct VkPipelineCreationFeedbackCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCreationFeedback* pPipelineCreationFeedback;
        uint32_t pipelineStageCreationFeedbackCount;
        VkPipelineCreationFeedback* pPipelineStageCreationFeedbacks;
    };

    struct VkPipelineCreationFeedbackCreateInfoEXT {
    };

    struct VkSurfaceFullScreenExclusiveInfoEXT {
        VkStructureType sType;
        void* pNext;
        VkFullScreenExclusiveEXT fullScreenExclusive;
    };

    struct VkSurfaceFullScreenExclusiveWin32InfoEXT {
        VkStructureType sType;
        const void* pNext;
        HMONITOR hmonitor;
    };

    struct VkSurfaceCapabilitiesFullScreenExclusiveEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 fullScreenExclusiveSupported;
    };

    struct VkPhysicalDevicePresentBarrierFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentBarrier;
    };

    struct VkSurfaceCapabilitiesPresentBarrierNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentBarrierSupported;
    };

    struct VkSwapchainPresentBarrierCreateInfoNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentBarrierEnable;
    };

    struct VkPhysicalDevicePerformanceQueryFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 performanceCounterQueryPools;
        VkBool32 performanceCounterMultipleQueryPools;
    };

    struct VkPhysicalDevicePerformanceQueryPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 allowCommandBufferQueryCopies;
    };

    struct VkPerformanceCounterKHR {
        VkStructureType sType;
        void* pNext;
        VkPerformanceCounterUnitKHR unit;
        VkPerformanceCounterScopeKHR scope;
        VkPerformanceCounterStorageKHR storage;
        uint8_t uuid[16];
    };

    struct VkPerformanceCounterDescriptionKHR {
        VkStructureType sType;
        void* pNext;
        VkPerformanceCounterDescriptionFlagsKHR flags;
        char name[256];
        char category[256];
        char description[256];
    };

    struct VkQueryPoolPerformanceCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t queueFamilyIndex;
        uint32_t counterIndexCount;
        const uint32_t* pCounterIndices;
    };

    union VkPerformanceCounterResultKHR {
        int32_t int32;
        int64_t int64;
        uint32_t uint32;
        uint64_t uint64;
        float float32;
        double float64;
    };

    struct VkAcquireProfilingLockInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkAcquireProfilingLockFlagsKHR flags;
        uint64_t timeout;
    };

    struct VkPerformanceQuerySubmitInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t counterPassIndex;
    };

    struct VkPerformanceQueryReservationInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t maxPerformanceQueriesPerPool;
    };

    struct VkHeadlessSurfaceCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkHeadlessSurfaceCreateFlagsEXT flags;
    };

    struct VkPhysicalDeviceCoverageReductionModeFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 coverageReductionMode;
    };

    struct VkPipelineCoverageReductionStateCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCoverageReductionStateCreateFlagsNV flags;
        VkCoverageReductionModeNV coverageReductionMode;
    };

    struct VkFramebufferMixedSamplesCombinationNV {
        VkStructureType sType;
        void* pNext;
        VkCoverageReductionModeNV coverageReductionMode;
        VkSampleCountFlagBits rasterizationSamples;
        VkSampleCountFlags depthStencilSamples;
        VkSampleCountFlags colorSamples;
    };

    struct VkPhysicalDeviceShaderIntegerFunctions2FeaturesINTEL {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderIntegerFunctions2;
    };

    union VkPerformanceValueDataINTEL {
        uint32_t value32;
        uint64_t value64;
        float valueFloat;
        VkBool32 valueBool;
        const char* valueString;
    };

    struct VkPerformanceValueINTEL {
        VkPerformanceValueTypeINTEL type;
        VkPerformanceValueDataINTEL data;
    };

    struct VkInitializePerformanceApiInfoINTEL {
        VkStructureType sType;
        const void* pNext;
        void* pUserData;
    };

    struct VkQueryPoolPerformanceQueryCreateInfoINTEL {
        VkStructureType sType;
        const void* pNext;
        VkQueryPoolSamplingModeINTEL performanceCountersSampling;
    };

    struct VkQueryPoolCreateInfoINTEL {
    };

    struct VkPerformanceMarkerInfoINTEL {
        VkStructureType sType;
        const void* pNext;
        uint64_t marker;
    };

    struct VkPerformanceStreamMarkerInfoINTEL {
        VkStructureType sType;
        const void* pNext;
        uint32_t marker;
    };

    struct VkPerformanceOverrideInfoINTEL {
        VkStructureType sType;
        const void* pNext;
        VkPerformanceOverrideTypeINTEL type;
        VkBool32 enable;
        uint64_t parameter;
    };

    struct VkPerformanceConfigurationAcquireInfoINTEL {
        VkStructureType sType;
        const void* pNext;
        VkPerformanceConfigurationTypeINTEL type;
    };

    struct VkPhysicalDeviceShaderClockFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderSubgroupClock;
        VkBool32 shaderDeviceClock;
    };

    struct VkPhysicalDeviceIndexTypeUint8Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 indexTypeUint8;
    };

    struct VkPhysicalDeviceIndexTypeUint8FeaturesKHR {
    };

    struct VkPhysicalDeviceIndexTypeUint8FeaturesEXT {
    };

    struct VkPhysicalDeviceShaderSMBuiltinsPropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t shaderSMCount;
        uint32_t shaderWarpsPerSM;
    };

    struct VkPhysicalDeviceShaderSMBuiltinsFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderSMBuiltins;
    };

    struct VkPhysicalDeviceFragmentShaderInterlockFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 fragmentShaderSampleInterlock;
        VkBool32 fragmentShaderPixelInterlock;
        VkBool32 fragmentShaderShadingRateInterlock;
    };

    struct VkPhysicalDeviceSeparateDepthStencilLayoutsFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 separateDepthStencilLayouts;
    };

    struct VkPhysicalDeviceSeparateDepthStencilLayoutsFeaturesKHR {
    };

    struct VkAttachmentReferenceStencilLayout {
        VkStructureType sType;
        void* pNext;
        VkImageLayout stencilLayout;
    };

    struct VkPhysicalDevicePrimitiveTopologyListRestartFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 primitiveTopologyListRestart;
        VkBool32 primitiveTopologyPatchListRestart;
    };

    struct VkAttachmentReferenceStencilLayoutKHR {
    };

    struct VkAttachmentDescriptionStencilLayout {
        VkStructureType sType;
        void* pNext;
        VkImageLayout stencilInitialLayout;
        VkImageLayout stencilFinalLayout;
    };

    struct VkAttachmentDescriptionStencilLayoutKHR {
    };

    struct VkPhysicalDevicePipelineExecutablePropertiesFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 pipelineExecutableInfo;
    };

    struct VkPipelineInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkPipeline pipeline;
    };

    struct VkPipelineInfoEXT {
    };

    struct VkPipelineExecutablePropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkShaderStageFlags stages;
        char name[256];
        char description[256];
        uint32_t subgroupSize;
    };

    struct VkPipelineExecutableInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkPipeline pipeline;
        uint32_t executableIndex;
    };

    union VkPipelineExecutableStatisticValueKHR {
        VkBool32 b32;
        int64_t i64;
        uint64_t u64;
        double f64;
    };

    struct VkPipelineExecutableStatisticKHR {
        VkStructureType sType;
        void* pNext;
        char name[256];
        char description[256];
        VkPipelineExecutableStatisticFormatKHR format;
        VkPipelineExecutableStatisticValueKHR value;
    };

    struct VkPipelineExecutableInternalRepresentationKHR {
        VkStructureType sType;
        void* pNext;
        char name[256];
        char description[256];
        VkBool32 isText;
        size_t dataSize;
        void* pData;
    };

    struct VkPhysicalDeviceShaderDemoteToHelperInvocationFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderDemoteToHelperInvocation;
    };

    struct VkPhysicalDeviceShaderDemoteToHelperInvocationFeaturesEXT {
    };

    struct VkPhysicalDeviceTexelBufferAlignmentFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 texelBufferAlignment;
    };

    struct VkPhysicalDeviceTexelBufferAlignmentProperties {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize storageTexelBufferOffsetAlignmentBytes;
        VkBool32 storageTexelBufferOffsetSingleTexelAlignment;
        VkDeviceSize uniformTexelBufferOffsetAlignmentBytes;
        VkBool32 uniformTexelBufferOffsetSingleTexelAlignment;
    };

    struct VkPhysicalDeviceTexelBufferAlignmentPropertiesEXT {
    };

    struct VkPhysicalDeviceSubgroupSizeControlFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 subgroupSizeControl;
        VkBool32 computeFullSubgroups;
    };

    struct VkPhysicalDeviceSubgroupSizeControlFeaturesEXT {
    };

    struct VkPhysicalDeviceSubgroupSizeControlProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t minSubgroupSize;
        uint32_t maxSubgroupSize;
        uint32_t maxComputeWorkgroupSubgroups;
        VkShaderStageFlags requiredSubgroupSizeStages;
    };

    struct VkPhysicalDeviceSubgroupSizeControlPropertiesEXT {
    };

    struct VkPipelineShaderStageRequiredSubgroupSizeCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t requiredSubgroupSize;
    };

    struct VkPipelineShaderStageRequiredSubgroupSizeCreateInfoEXT {
    };

    struct VkShaderRequiredSubgroupSizeCreateInfoEXT {
    };

    struct VkSubpassShadingPipelineCreateInfoHUAWEI {
        VkStructureType sType;
        void* pNext;
        VkRenderPass renderPass;
        uint32_t subpass;
    };

    struct VkPhysicalDeviceSubpassShadingPropertiesHUAWEI {
        VkStructureType sType;
        void* pNext;
        uint32_t maxSubpassShadingWorkgroupSizeAspectRatio;
    };

    struct VkPhysicalDeviceClusterCullingShaderPropertiesHUAWEI {
        VkStructureType sType;
        void* pNext;
        uint32_t maxWorkGroupCount[3];
        uint32_t maxWorkGroupSize[3];
        uint32_t maxOutputClusterCount;
        VkDeviceSize indirectBufferOffsetAlignment;
    };

    struct VkMemoryOpaqueCaptureAddressAllocateInfo {
        VkStructureType sType;
        const void* pNext;
        uint64_t opaqueCaptureAddress;
    };

    struct VkMemoryOpaqueCaptureAddressAllocateInfoKHR {
    };

    struct VkDeviceMemoryOpaqueCaptureAddressInfo {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
    };

    struct VkDeviceMemoryOpaqueCaptureAddressInfoKHR {
    };

    struct VkPhysicalDeviceLineRasterizationFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 rectangularLines;
        VkBool32 bresenhamLines;
        VkBool32 smoothLines;
        VkBool32 stippledRectangularLines;
        VkBool32 stippledBresenhamLines;
        VkBool32 stippledSmoothLines;
    };

    struct VkPhysicalDeviceLineRasterizationFeaturesKHR {
    };

    struct VkPhysicalDeviceLineRasterizationFeaturesEXT {
    };

    struct VkPhysicalDeviceLineRasterizationProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t lineSubPixelPrecisionBits;
    };

    struct VkPhysicalDeviceLineRasterizationPropertiesKHR {
    };

    struct VkPhysicalDeviceLineRasterizationPropertiesEXT {
    };

    struct VkPipelineRasterizationLineStateCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkLineRasterizationMode lineRasterizationMode;
        VkBool32 stippledLineEnable;
        uint32_t lineStippleFactor;
        uint16_t lineStipplePattern;
    };

    struct VkPipelineRasterizationLineStateCreateInfoKHR {
    };

    struct VkPipelineRasterizationLineStateCreateInfoEXT {
    };

    struct VkPhysicalDevicePipelineCreationCacheControlFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 pipelineCreationCacheControl;
    };

    struct VkPhysicalDevicePipelineCreationCacheControlFeaturesEXT {
    };

    struct VkPhysicalDeviceVulkan11Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 storageBuffer16BitAccess;
        VkBool32 uniformAndStorageBuffer16BitAccess;
        VkBool32 storagePushConstant16;
        VkBool32 storageInputOutput16;
        VkBool32 multiview;
        VkBool32 multiviewGeometryShader;
        VkBool32 multiviewTessellationShader;
        VkBool32 variablePointersStorageBuffer;
        VkBool32 variablePointers;
        VkBool32 protectedMemory;
        VkBool32 samplerYcbcrConversion;
        VkBool32 shaderDrawParameters;
    };

    struct VkPhysicalDeviceVulkan11Properties {
        VkStructureType sType;
        void* pNext;
        uint8_t deviceUUID[16];
        uint8_t driverUUID[16];
        uint8_t deviceLUID[8];
        uint32_t deviceNodeMask;
        VkBool32 deviceLUIDValid;
        uint32_t subgroupSize;
        VkShaderStageFlags subgroupSupportedStages;
        VkSubgroupFeatureFlags subgroupSupportedOperations;
        VkBool32 subgroupQuadOperationsInAllStages;
        VkPointClippingBehavior pointClippingBehavior;
        uint32_t maxMultiviewViewCount;
        uint32_t maxMultiviewInstanceIndex;
        VkBool32 protectedNoFault;
        uint32_t maxPerSetDescriptors;
        VkDeviceSize maxMemoryAllocationSize;
    };

    struct VkPhysicalDeviceVulkan12Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 samplerMirrorClampToEdge;
        VkBool32 drawIndirectCount;
        VkBool32 storageBuffer8BitAccess;
        VkBool32 uniformAndStorageBuffer8BitAccess;
        VkBool32 storagePushConstant8;
        VkBool32 shaderBufferInt64Atomics;
        VkBool32 shaderSharedInt64Atomics;
        VkBool32 shaderFloat16;
        VkBool32 shaderInt8;
        VkBool32 descriptorIndexing;
        VkBool32 shaderInputAttachmentArrayDynamicIndexing;
        VkBool32 shaderUniformTexelBufferArrayDynamicIndexing;
        VkBool32 shaderStorageTexelBufferArrayDynamicIndexing;
        VkBool32 shaderUniformBufferArrayNonUniformIndexing;
        VkBool32 shaderSampledImageArrayNonUniformIndexing;
        VkBool32 shaderStorageBufferArrayNonUniformIndexing;
        VkBool32 shaderStorageImageArrayNonUniformIndexing;
        VkBool32 shaderInputAttachmentArrayNonUniformIndexing;
        VkBool32 shaderUniformTexelBufferArrayNonUniformIndexing;
        VkBool32 shaderStorageTexelBufferArrayNonUniformIndexing;
        VkBool32 descriptorBindingUniformBufferUpdateAfterBind;
        VkBool32 descriptorBindingSampledImageUpdateAfterBind;
        VkBool32 descriptorBindingStorageImageUpdateAfterBind;
        VkBool32 descriptorBindingStorageBufferUpdateAfterBind;
        VkBool32 descriptorBindingUniformTexelBufferUpdateAfterBind;
        VkBool32 descriptorBindingStorageTexelBufferUpdateAfterBind;
        VkBool32 descriptorBindingUpdateUnusedWhilePending;
        VkBool32 descriptorBindingPartiallyBound;
        VkBool32 descriptorBindingVariableDescriptorCount;
        VkBool32 runtimeDescriptorArray;
        VkBool32 samplerFilterMinmax;
        VkBool32 scalarBlockLayout;
        VkBool32 imagelessFramebuffer;
        VkBool32 uniformBufferStandardLayout;
        VkBool32 shaderSubgroupExtendedTypes;
        VkBool32 separateDepthStencilLayouts;
        VkBool32 hostQueryReset;
        VkBool32 timelineSemaphore;
        VkBool32 bufferDeviceAddress;
        VkBool32 bufferDeviceAddressCaptureReplay;
        VkBool32 bufferDeviceAddressMultiDevice;
        VkBool32 vulkanMemoryModel;
        VkBool32 vulkanMemoryModelDeviceScope;
        VkBool32 vulkanMemoryModelAvailabilityVisibilityChains;
        VkBool32 shaderOutputViewportIndex;
        VkBool32 shaderOutputLayer;
        VkBool32 subgroupBroadcastDynamicId;
    };

    struct VkPhysicalDeviceVulkan12Properties {
        VkStructureType sType;
        void* pNext;
        VkDriverId driverID;
        char driverName[256];
        char driverInfo[256];
        VkConformanceVersion conformanceVersion;
        VkShaderFloatControlsIndependence denormBehaviorIndependence;
        VkShaderFloatControlsIndependence roundingModeIndependence;
        VkBool32 shaderSignedZeroInfNanPreserveFloat16;
        VkBool32 shaderSignedZeroInfNanPreserveFloat32;
        VkBool32 shaderSignedZeroInfNanPreserveFloat64;
        VkBool32 shaderDenormPreserveFloat16;
        VkBool32 shaderDenormPreserveFloat32;
        VkBool32 shaderDenormPreserveFloat64;
        VkBool32 shaderDenormFlushToZeroFloat16;
        VkBool32 shaderDenormFlushToZeroFloat32;
        VkBool32 shaderDenormFlushToZeroFloat64;
        VkBool32 shaderRoundingModeRTEFloat16;
        VkBool32 shaderRoundingModeRTEFloat32;
        VkBool32 shaderRoundingModeRTEFloat64;
        VkBool32 shaderRoundingModeRTZFloat16;
        VkBool32 shaderRoundingModeRTZFloat32;
        VkBool32 shaderRoundingModeRTZFloat64;
        uint32_t maxUpdateAfterBindDescriptorsInAllPools;
        VkBool32 shaderUniformBufferArrayNonUniformIndexingNative;
        VkBool32 shaderSampledImageArrayNonUniformIndexingNative;
        VkBool32 shaderStorageBufferArrayNonUniformIndexingNative;
        VkBool32 shaderStorageImageArrayNonUniformIndexingNative;
        VkBool32 shaderInputAttachmentArrayNonUniformIndexingNative;
        VkBool32 robustBufferAccessUpdateAfterBind;
        VkBool32 quadDivergentImplicitLod;
        uint32_t maxPerStageDescriptorUpdateAfterBindSamplers;
        uint32_t maxPerStageDescriptorUpdateAfterBindUniformBuffers;
        uint32_t maxPerStageDescriptorUpdateAfterBindStorageBuffers;
        uint32_t maxPerStageDescriptorUpdateAfterBindSampledImages;
        uint32_t maxPerStageDescriptorUpdateAfterBindStorageImages;
        uint32_t maxPerStageDescriptorUpdateAfterBindInputAttachments;
        uint32_t maxPerStageUpdateAfterBindResources;
        uint32_t maxDescriptorSetUpdateAfterBindSamplers;
        uint32_t maxDescriptorSetUpdateAfterBindUniformBuffers;
        uint32_t maxDescriptorSetUpdateAfterBindUniformBuffersDynamic;
        uint32_t maxDescriptorSetUpdateAfterBindStorageBuffers;
        uint32_t maxDescriptorSetUpdateAfterBindStorageBuffersDynamic;
        uint32_t maxDescriptorSetUpdateAfterBindSampledImages;
        uint32_t maxDescriptorSetUpdateAfterBindStorageImages;
        uint32_t maxDescriptorSetUpdateAfterBindInputAttachments;
        VkResolveModeFlags supportedDepthResolveModes;
        VkResolveModeFlags supportedStencilResolveModes;
        VkBool32 independentResolveNone;
        VkBool32 independentResolve;
        VkBool32 filterMinmaxSingleComponentFormats;
        VkBool32 filterMinmaxImageComponentMapping;
        uint64_t maxTimelineSemaphoreValueDifference;
        VkSampleCountFlags framebufferIntegerColorSampleCounts;
    };

    struct VkPhysicalDeviceVulkan13Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 robustImageAccess;
        VkBool32 inlineUniformBlock;
        VkBool32 descriptorBindingInlineUniformBlockUpdateAfterBind;
        VkBool32 pipelineCreationCacheControl;
        VkBool32 privateData;
        VkBool32 shaderDemoteToHelperInvocation;
        VkBool32 shaderTerminateInvocation;
        VkBool32 subgroupSizeControl;
        VkBool32 computeFullSubgroups;
        VkBool32 synchronization2;
        VkBool32 textureCompressionASTC_HDR;
        VkBool32 shaderZeroInitializeWorkgroupMemory;
        VkBool32 dynamicRendering;
        VkBool32 shaderIntegerDotProduct;
        VkBool32 maintenance4;
    };

    struct VkPhysicalDeviceVulkan13Properties {
        VkStructureType sType;
        void* pNext;
        uint32_t minSubgroupSize;
        uint32_t maxSubgroupSize;
        uint32_t maxComputeWorkgroupSubgroups;
        VkShaderStageFlags requiredSubgroupSizeStages;
        uint32_t maxInlineUniformBlockSize;
        uint32_t maxPerStageDescriptorInlineUniformBlocks;
        uint32_t maxPerStageDescriptorUpdateAfterBindInlineUniformBlocks;
        uint32_t maxDescriptorSetInlineUniformBlocks;
        uint32_t maxDescriptorSetUpdateAfterBindInlineUniformBlocks;
        uint32_t maxInlineUniformTotalSize;
        VkBool32 integerDotProduct8BitUnsignedAccelerated;
        VkBool32 integerDotProduct8BitSignedAccelerated;
        VkBool32 integerDotProduct8BitMixedSignednessAccelerated;
        VkBool32 integerDotProduct4x8BitPackedUnsignedAccelerated;
        VkBool32 integerDotProduct4x8BitPackedSignedAccelerated;
        VkBool32 integerDotProduct4x8BitPackedMixedSignednessAccelerated;
        VkBool32 integerDotProduct16BitUnsignedAccelerated;
        VkBool32 integerDotProduct16BitSignedAccelerated;
        VkBool32 integerDotProduct16BitMixedSignednessAccelerated;
        VkBool32 integerDotProduct32BitUnsignedAccelerated;
        VkBool32 integerDotProduct32BitSignedAccelerated;
        VkBool32 integerDotProduct32BitMixedSignednessAccelerated;
        VkBool32 integerDotProduct64BitUnsignedAccelerated;
        VkBool32 integerDotProduct64BitSignedAccelerated;
        VkBool32 integerDotProduct64BitMixedSignednessAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating8BitUnsignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating8BitSignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating8BitMixedSignednessAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating4x8BitPackedUnsignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating4x8BitPackedSignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating4x8BitPackedMixedSignednessAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating16BitUnsignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating16BitSignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating16BitMixedSignednessAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating32BitUnsignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating32BitSignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating32BitMixedSignednessAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating64BitUnsignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating64BitSignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating64BitMixedSignednessAccelerated;
        VkDeviceSize storageTexelBufferOffsetAlignmentBytes;
        VkBool32 storageTexelBufferOffsetSingleTexelAlignment;
        VkDeviceSize uniformTexelBufferOffsetAlignmentBytes;
        VkBool32 uniformTexelBufferOffsetSingleTexelAlignment;
        VkDeviceSize maxBufferSize;
    };

    struct VkPhysicalDeviceVulkan14Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 globalPriorityQuery;
        VkBool32 shaderSubgroupRotate;
        VkBool32 shaderSubgroupRotateClustered;
        VkBool32 shaderFloatControls2;
        VkBool32 shaderExpectAssume;
        VkBool32 rectangularLines;
        VkBool32 bresenhamLines;
        VkBool32 smoothLines;
        VkBool32 stippledRectangularLines;
        VkBool32 stippledBresenhamLines;
        VkBool32 stippledSmoothLines;
        VkBool32 vertexAttributeInstanceRateDivisor;
        VkBool32 vertexAttributeInstanceRateZeroDivisor;
        VkBool32 indexTypeUint8;
        VkBool32 dynamicRenderingLocalRead;
        VkBool32 maintenance5;
        VkBool32 maintenance6;
        VkBool32 pipelineProtectedAccess;
        VkBool32 pipelineRobustness;
        VkBool32 hostImageCopy;
        VkBool32 pushDescriptor;
    };

    struct VkPhysicalDeviceVulkan14Properties {
        VkStructureType sType;
        void* pNext;
        uint32_t lineSubPixelPrecisionBits;
        uint32_t maxVertexAttribDivisor;
        VkBool32 supportsNonZeroFirstInstance;
        uint32_t maxPushDescriptors;
        VkBool32 dynamicRenderingLocalReadDepthStencilAttachments;
        VkBool32 dynamicRenderingLocalReadMultisampledAttachments;
        VkBool32 earlyFragmentMultisampleCoverageAfterSampleCounting;
        VkBool32 earlyFragmentSampleMaskTestBeforeSampleCounting;
        VkBool32 depthStencilSwizzleOneSupport;
        VkBool32 polygonModePointSize;
        VkBool32 nonStrictSinglePixelWideLinesUseParallelogram;
        VkBool32 nonStrictWideLinesUseParallelogram;
        VkBool32 blockTexelViewCompatibleMultipleLayers;
        uint32_t maxCombinedImageSamplerDescriptorCount;
        VkBool32 fragmentShadingRateClampCombinerInputs;
        VkPipelineRobustnessBufferBehavior defaultRobustnessStorageBuffers;
        VkPipelineRobustnessBufferBehavior defaultRobustnessUniformBuffers;
        VkPipelineRobustnessBufferBehavior defaultRobustnessVertexInputs;
        VkPipelineRobustnessImageBehavior defaultRobustnessImages;
        uint32_t copySrcLayoutCount;
        VkImageLayout* pCopySrcLayouts;
        uint32_t copyDstLayoutCount;
        VkImageLayout* pCopyDstLayouts;
        uint8_t optimalTilingLayoutUUID[16];
        VkBool32 identicalMemoryTypeRequirements;
    };

    struct VkPipelineCompilerControlCreateInfoAMD {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCompilerControlFlagsAMD compilerControlFlags;
    };

    struct VkPhysicalDeviceCoherentMemoryFeaturesAMD {
        VkStructureType sType;
        void* pNext;
        VkBool32 deviceCoherentMemory;
    };

    struct VkFaultData {
        VkStructureType sType;
        void* pNext;
        VkFaultLevel faultLevel;
        VkFaultType faultType;
    };

    struct VkFaultCallbackInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t faultCount;
        VkFaultData* pFaults;
        PFN_vkFaultCallbackFunction pfnFaultCallback;
    };

    struct VkPhysicalDeviceToolProperties {
        VkStructureType sType;
        void* pNext;
        char name[256];
        char version[256];
        VkToolPurposeFlags purposes;
        char description[256];
        char layer[256];
    };

    struct VkPhysicalDeviceToolPropertiesEXT {
    };

    struct VkSamplerCustomBorderColorCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkClearColorValue customBorderColor;
        VkFormat format;
    };

    struct VkPhysicalDeviceCustomBorderColorPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t maxCustomBorderColorSamplers;
    };

    struct VkPhysicalDeviceCustomBorderColorFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 customBorderColors;
        VkBool32 customBorderColorWithoutFormat;
    };

    struct VkSamplerBorderColorComponentMappingCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkComponentMapping components;
        VkBool32 srgb;
    };

    struct VkPhysicalDeviceBorderColorSwizzleFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 borderColorSwizzle;
        VkBool32 borderColorSwizzleFromImage;
    };

    union VkDeviceOrHostAddressKHR {
        VkDeviceAddress deviceAddress;
        void* hostAddress;
    };

    union VkDeviceOrHostAddressConstKHR {
        VkDeviceAddress deviceAddress;
        const void* hostAddress;
    };

    union VkDeviceOrHostAddressConstAMDX {
        VkDeviceAddress deviceAddress;
        const void* hostAddress;
    };

    struct VkAccelerationStructureGeometryTrianglesDataKHR {
        VkStructureType sType;
        const void* pNext;
        VkFormat vertexFormat;
        VkDeviceOrHostAddressConstKHR vertexData;
        VkDeviceSize vertexStride;
        uint32_t maxVertex;
        VkIndexType indexType;
        VkDeviceOrHostAddressConstKHR indexData;
        VkDeviceOrHostAddressConstKHR transformData;
    };

    struct VkAccelerationStructureGeometryAabbsDataKHR {
        VkStructureType sType;
        const void* pNext;
        VkDeviceOrHostAddressConstKHR data;
        VkDeviceSize stride;
    };

    struct VkAccelerationStructureGeometryInstancesDataKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 arrayOfPointers;
        VkDeviceOrHostAddressConstKHR data;
    };

    struct VkAccelerationStructureGeometryLinearSweptSpheresDataNV {
        VkStructureType sType;
        const void* pNext;
        VkFormat vertexFormat;
        VkDeviceOrHostAddressConstKHR vertexData;
        VkDeviceSize vertexStride;
        VkFormat radiusFormat;
        VkDeviceOrHostAddressConstKHR radiusData;
        VkDeviceSize radiusStride;
        VkIndexType indexType;
        VkDeviceOrHostAddressConstKHR indexData;
        VkDeviceSize indexStride;
        VkRayTracingLssIndexingModeNV indexingMode;
        VkRayTracingLssPrimitiveEndCapsModeNV endCapsMode;
    };

    struct VkAccelerationStructureGeometrySpheresDataNV {
        VkStructureType sType;
        const void* pNext;
        VkFormat vertexFormat;
        VkDeviceOrHostAddressConstKHR vertexData;
        VkDeviceSize vertexStride;
        VkFormat radiusFormat;
        VkDeviceOrHostAddressConstKHR radiusData;
        VkDeviceSize radiusStride;
        VkIndexType indexType;
        VkDeviceOrHostAddressConstKHR indexData;
        VkDeviceSize indexStride;
    };

    union VkAccelerationStructureGeometryDataKHR {
        VkAccelerationStructureGeometryTrianglesDataKHR triangles;
        VkAccelerationStructureGeometryAabbsDataKHR aabbs;
        VkAccelerationStructureGeometryInstancesDataKHR instances;
    };

    struct VkAccelerationStructureGeometryKHR {
        VkStructureType sType;
        const void* pNext;
        VkGeometryTypeKHR geometryType;
        VkAccelerationStructureGeometryDataKHR geometry;
        VkGeometryFlagsKHR flags;
    };

    struct VkAccelerationStructureBuildGeometryInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkAccelerationStructureTypeKHR type;
        VkBuildAccelerationStructureFlagsKHR flags;
        VkBuildAccelerationStructureModeKHR mode;
        VkAccelerationStructureKHR srcAccelerationStructure;
        VkAccelerationStructureKHR dstAccelerationStructure;
        uint32_t geometryCount;
        const VkAccelerationStructureGeometryKHR* pGeometries;
        const VkAccelerationStructureGeometryKHR* const* ppGeometries;
        VkDeviceOrHostAddressKHR scratchData;
    };

    struct VkAccelerationStructureBuildRangeInfoKHR {
        uint32_t primitiveCount;
        uint32_t primitiveOffset;
        uint32_t firstVertex;
        uint32_t transformOffset;
    };

    struct VkAccelerationStructureCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkAccelerationStructureCreateFlagsKHR createFlags;
        VkBuffer buffer;
        VkDeviceSize offset;
        VkDeviceSize size;
        VkAccelerationStructureTypeKHR type;
        VkDeviceAddress deviceAddress;
    };

    struct VkAabbPositionsKHR {
        float minX;
        float minY;
        float minZ;
        float maxX;
        float maxY;
        float maxZ;
    };

    struct VkAabbPositionsNV {
    };

    struct VkTransformMatrixKHR {
        float matrix[3][4];
    };

    struct VkTransformMatrixNV {
    };

    struct VkAccelerationStructureInstanceKHR {
        VkTransformMatrixKHR transform;
        uint32_t instanceCustomIndex;
        uint32_t mask;
        uint32_t instanceShaderBindingTableRecordOffset;
        VkGeometryInstanceFlagsKHR flags;
        uint64_t accelerationStructureReference;
    };

    struct VkAccelerationStructureInstanceNV {
    };

    struct VkAccelerationStructureDeviceAddressInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkAccelerationStructureKHR accelerationStructure;
    };

    struct VkAccelerationStructureVersionInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const uint8_t* pVersionData;
    };

    struct VkCopyAccelerationStructureInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkAccelerationStructureKHR src;
        VkAccelerationStructureKHR dst;
        VkCopyAccelerationStructureModeKHR mode;
    };

    struct VkCopyAccelerationStructureToMemoryInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkAccelerationStructureKHR src;
        VkDeviceOrHostAddressKHR dst;
        VkCopyAccelerationStructureModeKHR mode;
    };

    struct VkCopyMemoryToAccelerationStructureInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkDeviceOrHostAddressConstKHR src;
        VkAccelerationStructureKHR dst;
        VkCopyAccelerationStructureModeKHR mode;
    };

    struct VkRayTracingPipelineInterfaceCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t maxPipelineRayPayloadSize;
        uint32_t maxPipelineRayHitAttributeSize;
    };

    struct VkPipelineLibraryCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t libraryCount;
        const VkPipeline* pLibraries;
    };

    struct VkRefreshObjectKHR {
        VkObjectType objectType;
        uint64_t objectHandle;
        VkRefreshObjectFlagsKHR flags;
    };

    struct VkRefreshObjectListKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t objectCount;
        const VkRefreshObjectKHR* pObjects;
    };

    struct VkPhysicalDeviceExtendedDynamicStateFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 extendedDynamicState;
    };

    struct VkPhysicalDeviceExtendedDynamicState2FeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 extendedDynamicState2;
        VkBool32 extendedDynamicState2LogicOp;
        VkBool32 extendedDynamicState2PatchControlPoints;
    };

    struct VkPhysicalDeviceExtendedDynamicState3FeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 extendedDynamicState3TessellationDomainOrigin;
        VkBool32 extendedDynamicState3DepthClampEnable;
        VkBool32 extendedDynamicState3PolygonMode;
        VkBool32 extendedDynamicState3RasterizationSamples;
        VkBool32 extendedDynamicState3SampleMask;
        VkBool32 extendedDynamicState3AlphaToCoverageEnable;
        VkBool32 extendedDynamicState3AlphaToOneEnable;
        VkBool32 extendedDynamicState3LogicOpEnable;
        VkBool32 extendedDynamicState3ColorBlendEnable;
        VkBool32 extendedDynamicState3ColorBlendEquation;
        VkBool32 extendedDynamicState3ColorWriteMask;
        VkBool32 extendedDynamicState3RasterizationStream;
        VkBool32 extendedDynamicState3ConservativeRasterizationMode;
        VkBool32 extendedDynamicState3ExtraPrimitiveOverestimationSize;
        VkBool32 extendedDynamicState3DepthClipEnable;
        VkBool32 extendedDynamicState3SampleLocationsEnable;
        VkBool32 extendedDynamicState3ColorBlendAdvanced;
        VkBool32 extendedDynamicState3ProvokingVertexMode;
        VkBool32 extendedDynamicState3LineRasterizationMode;
        VkBool32 extendedDynamicState3LineStippleEnable;
        VkBool32 extendedDynamicState3DepthClipNegativeOneToOne;
        VkBool32 extendedDynamicState3ViewportWScalingEnable;
        VkBool32 extendedDynamicState3ViewportSwizzle;
        VkBool32 extendedDynamicState3CoverageToColorEnable;
        VkBool32 extendedDynamicState3CoverageToColorLocation;
        VkBool32 extendedDynamicState3CoverageModulationMode;
        VkBool32 extendedDynamicState3CoverageModulationTableEnable;
        VkBool32 extendedDynamicState3CoverageModulationTable;
        VkBool32 extendedDynamicState3CoverageReductionMode;
        VkBool32 extendedDynamicState3RepresentativeFragmentTestEnable;
        VkBool32 extendedDynamicState3ShadingRateImageEnable;
    };

    struct VkPhysicalDeviceExtendedDynamicState3PropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 dynamicPrimitiveTopologyUnrestricted;
    };

    struct VkColorBlendEquationEXT {
        VkBlendFactor srcColorBlendFactor;
        VkBlendFactor dstColorBlendFactor;
        VkBlendOp colorBlendOp;
        VkBlendFactor srcAlphaBlendFactor;
        VkBlendFactor dstAlphaBlendFactor;
        VkBlendOp alphaBlendOp;
    };

    struct VkColorBlendAdvancedEXT {
        VkBlendOp advancedBlendOp;
        VkBool32 srcPremultiplied;
        VkBool32 dstPremultiplied;
        VkBlendOverlapEXT blendOverlap;
        VkBool32 clampResults;
    };

    struct VkRenderPassTransformBeginInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        VkSurfaceTransformFlagBitsKHR transform;
    };

    struct VkCopyCommandTransformInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        VkSurfaceTransformFlagBitsKHR transform;
    };

    struct VkCommandBufferInheritanceRenderPassTransformInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        VkSurfaceTransformFlagBitsKHR transform;
        VkRect2D renderArea;
    };

    struct VkPhysicalDevicePartitionedAccelerationStructureFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 partitionedAccelerationStructure;
    };

    struct VkPhysicalDevicePartitionedAccelerationStructurePropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t maxPartitionCount;
    };

    struct VkBuildPartitionedAccelerationStructureIndirectCommandNV {
        VkPartitionedAccelerationStructureOpTypeNV opType;
        uint32_t argCount;
        VkStridedDeviceAddressNV argData;
    };

    struct VkPartitionedAccelerationStructureFlagsNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 enablePartitionTranslation;
    };

    struct VkPartitionedAccelerationStructureWriteInstanceDataNV {
        VkTransformMatrixKHR transform;
        float explicitAABB[6];
        uint32_t instanceID;
        uint32_t instanceMask;
        uint32_t instanceContributionToHitGroupIndex;
        VkPartitionedAccelerationStructureInstanceFlagsNV instanceFlags;
        uint32_t instanceIndex;
        uint32_t partitionIndex;
        VkDeviceAddress accelerationStructure;
    };

    struct VkPartitionedAccelerationStructureUpdateInstanceDataNV {
        uint32_t instanceIndex;
        uint32_t instanceContributionToHitGroupIndex;
        VkDeviceAddress accelerationStructure;
    };

    struct VkPartitionedAccelerationStructureWritePartitionTranslationDataNV {
        uint32_t partitionIndex;
        float partitionTranslation[3];
    };

    struct VkWriteDescriptorSetPartitionedAccelerationStructureNV {
        VkStructureType sType;
        void* pNext;
        uint32_t accelerationStructureCount;
        const VkDeviceAddress* pAccelerationStructures;
    };

    struct VkPartitionedAccelerationStructureInstancesInputNV {
        VkStructureType sType;
        void* pNext;
        VkBuildAccelerationStructureFlagsKHR flags;
        uint32_t instanceCount;
        uint32_t maxInstancePerPartitionCount;
        uint32_t partitionCount;
        uint32_t maxInstanceInGlobalPartitionCount;
    };

    struct VkBuildPartitionedAccelerationStructureInfoNV {
        VkStructureType sType;
        void* pNext;
        VkPartitionedAccelerationStructureInstancesInputNV input;
        VkDeviceAddress srcAccelerationStructureData;
        VkDeviceAddress dstAccelerationStructureData;
        VkDeviceAddress scratchData;
        VkDeviceAddress srcInfos;
        VkDeviceAddress srcInfosCount;
    };

    struct VkPhysicalDeviceDiagnosticsConfigFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 diagnosticsConfig;
    };

    struct VkDeviceDiagnosticsConfigCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkDeviceDiagnosticsConfigFlagsNV flags;
    };

    struct VkPipelineOfflineCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint8_t pipelineIdentifier[16];
        VkPipelineMatchControl matchControl;
        VkDeviceSize poolEntrySize;
    };

    struct VkPhysicalDeviceZeroInitializeWorkgroupMemoryFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderZeroInitializeWorkgroupMemory;
    };

    struct VkPhysicalDeviceZeroInitializeWorkgroupMemoryFeaturesKHR {
    };

    struct VkPhysicalDeviceShaderSubgroupUniformControlFlowFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderSubgroupUniformControlFlow;
    };

    struct VkPhysicalDeviceRobustness2FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 robustBufferAccess2;
        VkBool32 robustImageAccess2;
        VkBool32 nullDescriptor;
    };

    struct VkPhysicalDeviceRobustness2FeaturesEXT {
    };

    struct VkPhysicalDeviceRobustness2PropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize robustStorageBufferAccessSizeAlignment;
        VkDeviceSize robustUniformBufferAccessSizeAlignment;
    };

    struct VkPhysicalDeviceRobustness2PropertiesEXT {
    };

    struct VkPhysicalDeviceImageRobustnessFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 robustImageAccess;
    };

    struct VkPhysicalDeviceImageRobustnessFeaturesEXT {
    };

    struct VkPhysicalDeviceWorkgroupMemoryExplicitLayoutFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 workgroupMemoryExplicitLayout;
        VkBool32 workgroupMemoryExplicitLayoutScalarBlockLayout;
        VkBool32 workgroupMemoryExplicitLayout8BitAccess;
        VkBool32 workgroupMemoryExplicitLayout16BitAccess;
    };

    struct VkPhysicalDevicePortabilitySubsetFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 constantAlphaColorBlendFactors;
        VkBool32 events;
        VkBool32 imageViewFormatReinterpretation;
        VkBool32 imageViewFormatSwizzle;
        VkBool32 imageView2DOn3DImage;
        VkBool32 multisampleArrayImage;
        VkBool32 mutableComparisonSamplers;
        VkBool32 pointPolygons;
        VkBool32 samplerMipLodBias;
        VkBool32 separateStencilMaskRef;
        VkBool32 shaderSampleRateInterpolationFunctions;
        VkBool32 tessellationIsolines;
        VkBool32 tessellationPointMode;
        VkBool32 triangleFans;
        VkBool32 vertexAttributeAccessBeyondStride;
    };

    struct VkPhysicalDevicePortabilitySubsetPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t minVertexInputBindingStrideAlignment;
    };

    struct VkPhysicalDevice4444FormatsFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 formatA4R4G4B4;
        VkBool32 formatA4B4G4R4;
    };

    struct VkPhysicalDeviceSubpassShadingFeaturesHUAWEI {
        VkStructureType sType;
        void* pNext;
        VkBool32 subpassShading;
    };

    struct VkPhysicalDeviceClusterCullingShaderFeaturesHUAWEI {
        VkStructureType sType;
        void* pNext;
        VkBool32 clustercullingShader;
        VkBool32 multiviewClusterCullingShader;
    };

    struct VkPhysicalDeviceClusterCullingShaderVrsFeaturesHUAWEI {
        VkStructureType sType;
        void* pNext;
        VkBool32 clusterShadingRate;
    };

    struct VkBufferCopy2 {
        VkStructureType sType;
        const void* pNext;
        VkDeviceSize srcOffset;
        VkDeviceSize dstOffset;
        VkDeviceSize size;
    };

    struct VkBufferCopy2KHR {
    };

    struct VkImageCopy2 {
        VkStructureType sType;
        const void* pNext;
        VkImageSubresourceLayers srcSubresource;
        VkOffset3D srcOffset;
        VkImageSubresourceLayers dstSubresource;
        VkOffset3D dstOffset;
        VkExtent3D extent;
    };

    struct VkImageCopy2KHR {
    };

    struct VkImageBlit2 {
        VkStructureType sType;
        const void* pNext;
        VkImageSubresourceLayers srcSubresource;
        VkOffset3D srcOffsets[2];
        VkImageSubresourceLayers dstSubresource;
        VkOffset3D dstOffsets[2];
    };

    struct VkImageBlit2KHR {
    };

    struct VkBufferImageCopy2 {
        VkStructureType sType;
        const void* pNext;
        VkDeviceSize bufferOffset;
        uint32_t bufferRowLength;
        uint32_t bufferImageHeight;
        VkImageSubresourceLayers imageSubresource;
        VkOffset3D imageOffset;
        VkExtent3D imageExtent;
    };

    struct VkBufferImageCopy2KHR {
    };

    struct VkImageResolve2 {
        VkStructureType sType;
        const void* pNext;
        VkImageSubresourceLayers srcSubresource;
        VkOffset3D srcOffset;
        VkImageSubresourceLayers dstSubresource;
        VkOffset3D dstOffset;
        VkExtent3D extent;
    };

    struct VkImageResolve2KHR {
    };

    struct VkCopyBufferInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkBuffer srcBuffer;
        VkBuffer dstBuffer;
        uint32_t regionCount;
        const VkBufferCopy2* pRegions;
    };

    struct VkCopyBufferInfo2KHR {
    };

    struct VkCopyImageInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkImage srcImage;
        VkImageLayout srcImageLayout;
        VkImage dstImage;
        VkImageLayout dstImageLayout;
        uint32_t regionCount;
        const VkImageCopy2* pRegions;
    };

    struct VkCopyImageInfo2KHR {
    };

    struct VkBlitImageInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkImage srcImage;
        VkImageLayout srcImageLayout;
        VkImage dstImage;
        VkImageLayout dstImageLayout;
        uint32_t regionCount;
        const VkImageBlit2* pRegions;
        VkFilter filter;
    };

    struct VkBlitImageInfo2KHR {
    };

    struct VkCopyBufferToImageInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkBuffer srcBuffer;
        VkImage dstImage;
        VkImageLayout dstImageLayout;
        uint32_t regionCount;
        const VkBufferImageCopy2* pRegions;
    };

    struct VkCopyBufferToImageInfo2KHR {
    };

    struct VkCopyImageToBufferInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkImage srcImage;
        VkImageLayout srcImageLayout;
        VkBuffer dstBuffer;
        uint32_t regionCount;
        const VkBufferImageCopy2* pRegions;
    };

    struct VkCopyImageToBufferInfo2KHR {
    };

    struct VkResolveImageInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkImage srcImage;
        VkImageLayout srcImageLayout;
        VkImage dstImage;
        VkImageLayout dstImageLayout;
        uint32_t regionCount;
        const VkImageResolve2* pRegions;
    };

    struct VkResolveImageInfo2KHR {
    };

    struct VkPhysicalDeviceShaderImageAtomicInt64FeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderImageInt64Atomics;
        VkBool32 sparseImageInt64Atomics;
    };

    struct VkFragmentShadingRateAttachmentInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const VkAttachmentReference2* pFragmentShadingRateAttachment;
        VkExtent2D shadingRateAttachmentTexelSize;
    };

    struct VkPipelineFragmentShadingRateStateCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkExtent2D fragmentSize;
        VkFragmentShadingRateCombinerOpKHR combinerOps[2];
    };

    struct VkPhysicalDeviceFragmentShadingRateFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 pipelineFragmentShadingRate;
        VkBool32 primitiveFragmentShadingRate;
        VkBool32 attachmentFragmentShadingRate;
    };

    struct VkPhysicalDeviceFragmentShadingRatePropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkExtent2D minFragmentShadingRateAttachmentTexelSize;
        VkExtent2D maxFragmentShadingRateAttachmentTexelSize;
        uint32_t maxFragmentShadingRateAttachmentTexelSizeAspectRatio;
        VkBool32 primitiveFragmentShadingRateWithMultipleViewports;
        VkBool32 layeredShadingRateAttachments;
        VkBool32 fragmentShadingRateNonTrivialCombinerOps;
        VkExtent2D maxFragmentSize;
        uint32_t maxFragmentSizeAspectRatio;
        uint32_t maxFragmentShadingRateCoverageSamples;
        VkSampleCountFlagBits maxFragmentShadingRateRasterizationSamples;
        VkBool32 fragmentShadingRateWithShaderDepthStencilWrites;
        VkBool32 fragmentShadingRateWithSampleMask;
        VkBool32 fragmentShadingRateWithShaderSampleMask;
        VkBool32 fragmentShadingRateWithConservativeRasterization;
        VkBool32 fragmentShadingRateWithFragmentShaderInterlock;
        VkBool32 fragmentShadingRateWithCustomSampleLocations;
        VkBool32 fragmentShadingRateStrictMultiplyCombiner;
    };

    struct VkPhysicalDeviceFragmentShadingRateKHR {
        VkStructureType sType;
        void* pNext;
        VkSampleCountFlags sampleCounts;
        VkExtent2D fragmentSize;
    };

    struct VkPhysicalDeviceShaderTerminateInvocationFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderTerminateInvocation;
    };

    struct VkPhysicalDeviceShaderTerminateInvocationFeaturesKHR {
    };

    struct VkPhysicalDeviceFragmentShadingRateEnumsFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 fragmentShadingRateEnums;
        VkBool32 supersampleFragmentShadingRates;
        VkBool32 noInvocationFragmentShadingRates;
    };

    struct VkPhysicalDeviceFragmentShadingRateEnumsPropertiesNV {
        VkStructureType sType;
        void* pNext;
        VkSampleCountFlagBits maxFragmentShadingRateInvocationCount;
    };

    struct VkPipelineFragmentShadingRateEnumStateCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkFragmentShadingRateTypeNV shadingRateType;
        VkFragmentShadingRateNV shadingRate;
        VkFragmentShadingRateCombinerOpKHR combinerOps[2];
    };

    struct VkAccelerationStructureBuildSizesInfoKHR {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize accelerationStructureSize;
        VkDeviceSize updateScratchSize;
        VkDeviceSize buildScratchSize;
    };

    struct VkPhysicalDeviceImage2DViewOf3DFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 image2DViewOf3D;
        VkBool32 sampler2DViewOf3D;
    };

    struct VkPhysicalDeviceImageSlicedViewOf3DFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 imageSlicedViewOf3D;
    };

    struct VkPhysicalDeviceAttachmentFeedbackLoopDynamicStateFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 attachmentFeedbackLoopDynamicState;
    };

    struct VkPhysicalDeviceLegacyVertexAttributesFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 legacyVertexAttributes;
    };

    struct VkPhysicalDeviceLegacyVertexAttributesPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 nativeUnalignedPerformance;
    };

    struct VkPhysicalDeviceMutableDescriptorTypeFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 mutableDescriptorType;
    };

    struct VkPhysicalDeviceMutableDescriptorTypeFeaturesVALVE {
    };

    struct VkMutableDescriptorTypeListEXT {
        uint32_t descriptorTypeCount;
        const VkDescriptorType* pDescriptorTypes;
    };

    struct VkMutableDescriptorTypeListVALVE {
    };

    struct VkMutableDescriptorTypeCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t mutableDescriptorTypeListCount;
        const VkMutableDescriptorTypeListEXT* pMutableDescriptorTypeLists;
    };

    struct VkMutableDescriptorTypeCreateInfoVALVE {
    };

    struct VkPhysicalDeviceDepthClipControlFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 depthClipControl;
    };

    struct VkPhysicalDeviceZeroInitializeDeviceMemoryFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 zeroInitializeDeviceMemory;
    };

    struct VkBeginCustomResolveInfoEXT {
        VkStructureType sType;
        void* pNext;
    };

    struct VkPhysicalDeviceCustomResolveFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 customResolve;
    };

    struct VkCustomResolveCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkBool32 customResolve;
        uint32_t colorAttachmentCount;
        const VkFormat* pColorAttachmentFormats;
        VkFormat depthAttachmentFormat;
        VkFormat stencilAttachmentFormat;
    };

    struct VkPhysicalDeviceDeviceGeneratedCommandsFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 deviceGeneratedCommands;
        VkBool32 dynamicGeneratedPipelineLayout;
    };

    struct VkPhysicalDeviceDeviceGeneratedCommandsPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t maxIndirectPipelineCount;
        uint32_t maxIndirectShaderObjectCount;
        uint32_t maxIndirectSequenceCount;
        uint32_t maxIndirectCommandsTokenCount;
        uint32_t maxIndirectCommandsTokenOffset;
        uint32_t maxIndirectCommandsIndirectStride;
        VkIndirectCommandsInputModeFlagsEXT supportedIndirectCommandsInputModes;
        VkShaderStageFlags supportedIndirectCommandsShaderStages;
        VkShaderStageFlags supportedIndirectCommandsShaderStagesPipelineBinding;
        VkShaderStageFlags supportedIndirectCommandsShaderStagesShaderBinding;
        VkBool32 deviceGeneratedCommandsTransformFeedback;
        VkBool32 deviceGeneratedCommandsMultiDrawIndirectCount;
    };

    struct VkGeneratedCommandsPipelineInfoEXT {
        VkStructureType sType;
        void* pNext;
        VkPipeline pipeline;
    };

    struct VkGeneratedCommandsShaderInfoEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t shaderCount;
        const VkShaderEXT* pShaders;
    };

    struct VkGeneratedCommandsMemoryRequirementsInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkIndirectExecutionSetEXT indirectExecutionSet;
        VkIndirectCommandsLayoutEXT indirectCommandsLayout;
        uint32_t maxSequenceCount;
        uint32_t maxDrawCount;
    };

    struct VkIndirectExecutionSetPipelineInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkPipeline initialPipeline;
        uint32_t maxPipelineCount;
    };

    struct VkIndirectExecutionSetShaderLayoutInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t setLayoutCount;
        const VkDescriptorSetLayout* pSetLayouts;
    };

    struct VkIndirectExecutionSetShaderInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t shaderCount;
        const VkShaderEXT* pInitialShaders;
        const VkIndirectExecutionSetShaderLayoutInfoEXT* pSetLayoutInfos;
        uint32_t maxShaderCount;
        uint32_t pushConstantRangeCount;
        const VkPushConstantRange* pPushConstantRanges;
    };

    union VkIndirectExecutionSetInfoEXT {
        const VkIndirectExecutionSetPipelineInfoEXT* pPipelineInfo;
        const VkIndirectExecutionSetShaderInfoEXT* pShaderInfo;
    };

    struct VkIndirectExecutionSetCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkIndirectExecutionSetInfoTypeEXT type;
        VkIndirectExecutionSetInfoEXT info;
    };

    struct VkGeneratedCommandsInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkShaderStageFlags shaderStages;
        VkIndirectExecutionSetEXT indirectExecutionSet;
        VkIndirectCommandsLayoutEXT indirectCommandsLayout;
        VkDeviceAddress indirectAddress;
        VkDeviceSize indirectAddressSize;
        VkDeviceAddress preprocessAddress;
        VkDeviceSize preprocessSize;
        uint32_t maxSequenceCount;
        VkDeviceAddress sequenceCountAddress;
        uint32_t maxDrawCount;
    };

    struct VkWriteIndirectExecutionSetPipelineEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t index;
        VkPipeline pipeline;
    };

    struct VkWriteIndirectExecutionSetShaderEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t index;
        VkShaderEXT shader;
    };

    struct VkIndirectCommandsLayoutCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkIndirectCommandsLayoutUsageFlagsEXT flags;
        VkShaderStageFlags shaderStages;
        uint32_t indirectStride;
        VkPipelineLayout pipelineLayout;
        uint32_t tokenCount;
        const VkIndirectCommandsLayoutTokenEXT* pTokens;
    };

    union VkIndirectCommandsTokenDataEXT {
        const VkIndirectCommandsPushConstantTokenEXT* pPushConstant;
        const VkIndirectCommandsVertexBufferTokenEXT* pVertexBuffer;
        const VkIndirectCommandsIndexBufferTokenEXT* pIndexBuffer;
        const VkIndirectCommandsExecutionSetTokenEXT* pExecutionSet;
    };

    struct VkIndirectCommandsLayoutTokenEXT {
        VkStructureType sType;
        const void* pNext;
        VkIndirectCommandsTokenTypeEXT type;
        VkIndirectCommandsTokenDataEXT data;
        uint32_t offset;
    };

    struct VkDrawIndirectCountIndirectCommandEXT {
        VkDeviceAddress bufferAddress;
        uint32_t stride;
        uint32_t commandCount;
    };

    struct VkIndirectCommandsVertexBufferTokenEXT {
        uint32_t vertexBindingUnit;
    };

    struct VkBindVertexBufferIndirectCommandEXT {
        VkDeviceAddress bufferAddress;
        uint32_t size;
        uint32_t stride;
    };

    struct VkIndirectCommandsIndexBufferTokenEXT {
        VkIndirectCommandsInputModeFlagBitsEXT mode;
    };

    struct VkBindIndexBufferIndirectCommandEXT {
        VkDeviceAddress bufferAddress;
        uint32_t size;
        VkIndexType indexType;
    };

    struct VkIndirectCommandsPushConstantTokenEXT {
        VkPushConstantRange updateRange;
    };

    struct VkIndirectCommandsExecutionSetTokenEXT {
        VkIndirectExecutionSetInfoTypeEXT type;
        VkShaderStageFlags shaderStages;
    };

    struct VkPipelineViewportDepthClipControlCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkBool32 negativeOneToOne;
    };

    struct VkPhysicalDeviceDepthClampControlFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 depthClampControl;
    };

    struct VkPipelineViewportDepthClampControlCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDepthClampModeEXT depthClampMode;
        const VkDepthClampRangeEXT* pDepthClampRange;
    };

    struct VkPhysicalDeviceVertexInputDynamicStateFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 vertexInputDynamicState;
    };

    struct VkPhysicalDeviceExternalMemoryRDMAFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 externalMemoryRDMA;
    };

    struct VkPhysicalDeviceShaderRelaxedExtendedInstructionFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderRelaxedExtendedInstruction;
    };

    struct VkVertexInputBindingDescription2EXT {
        VkStructureType sType;
        void* pNext;
        uint32_t binding;
        uint32_t stride;
        VkVertexInputRate inputRate;
        uint32_t divisor;
    };

    struct VkVertexInputAttributeDescription2EXT {
        VkStructureType sType;
        void* pNext;
        uint32_t location;
        uint32_t binding;
        VkFormat format;
        uint32_t offset;
    };

    struct VkPhysicalDeviceColorWriteEnableFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 colorWriteEnable;
    };

    struct VkPipelineColorWriteCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t attachmentCount;
        const VkBool32* pColorWriteEnables;
    };

    struct VkMemoryBarrier2 {
        VkStructureType sType;
        const void* pNext;
        VkPipelineStageFlags2 srcStageMask;
        VkAccessFlags2 srcAccessMask;
        VkPipelineStageFlags2 dstStageMask;
        VkAccessFlags2 dstAccessMask;
    };

    struct VkMemoryBarrier2KHR {
    };

    struct VkImageMemoryBarrier2 {
        VkStructureType sType;
        const void* pNext;
        VkPipelineStageFlags2 srcStageMask;
        VkAccessFlags2 srcAccessMask;
        VkPipelineStageFlags2 dstStageMask;
        VkAccessFlags2 dstAccessMask;
        VkImageLayout oldLayout;
        VkImageLayout newLayout;
        uint32_t srcQueueFamilyIndex;
        uint32_t dstQueueFamilyIndex;
        VkImage image;
        VkImageSubresourceRange subresourceRange;
    };

    struct VkImageMemoryBarrier2KHR {
    };

    struct VkBufferMemoryBarrier2 {
        VkStructureType sType;
        const void* pNext;
        VkPipelineStageFlags2 srcStageMask;
        VkAccessFlags2 srcAccessMask;
        VkPipelineStageFlags2 dstStageMask;
        VkAccessFlags2 dstAccessMask;
        uint32_t srcQueueFamilyIndex;
        uint32_t dstQueueFamilyIndex;
        VkBuffer buffer;
        VkDeviceSize offset;
        VkDeviceSize size;
    };

    struct VkBufferMemoryBarrier2KHR {
    };

    struct VkMemoryBarrierAccessFlags3KHR {
        VkStructureType sType;
        const void* pNext;
        VkAccessFlags3KHR srcAccessMask3;
        VkAccessFlags3KHR dstAccessMask3;
    };

    struct VkDependencyInfo {
        VkStructureType sType;
        const void* pNext;
        VkDependencyFlags dependencyFlags;
        uint32_t memoryBarrierCount;
        const VkMemoryBarrier2* pMemoryBarriers;
        uint32_t bufferMemoryBarrierCount;
        const VkBufferMemoryBarrier2* pBufferMemoryBarriers;
        uint32_t imageMemoryBarrierCount;
        const VkImageMemoryBarrier2* pImageMemoryBarriers;
    };

    struct VkDependencyInfoKHR {
    };

    struct VkSemaphoreSubmitInfo {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore semaphore;
        uint64_t value;
        VkPipelineStageFlags2 stageMask;
        uint32_t deviceIndex;
    };

    struct VkSemaphoreSubmitInfoKHR {
    };

    struct VkCommandBufferSubmitInfo {
        VkStructureType sType;
        const void* pNext;
        VkCommandBuffer commandBuffer;
        uint32_t deviceMask;
    };

    struct VkCommandBufferSubmitInfoKHR {
    };

    struct VkSubmitInfo2 {
        VkStructureType sType;
        const void* pNext;
        VkSubmitFlags flags;
        uint32_t waitSemaphoreInfoCount;
        const VkSemaphoreSubmitInfo* pWaitSemaphoreInfos;
        uint32_t commandBufferInfoCount;
        const VkCommandBufferSubmitInfo* pCommandBufferInfos;
        uint32_t signalSemaphoreInfoCount;
        const VkSemaphoreSubmitInfo* pSignalSemaphoreInfos;
    };

    struct VkSubmitInfo2KHR {
    };

    struct VkQueueFamilyCheckpointProperties2NV {
        VkStructureType sType;
        void* pNext;
        VkPipelineStageFlags2 checkpointExecutionStageMask;
    };

    struct VkCheckpointData2NV {
        VkStructureType sType;
        void* pNext;
        VkPipelineStageFlags2 stage;
        void* pCheckpointMarker;
    };

    struct VkPhysicalDeviceSynchronization2Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 synchronization2;
    };

    struct VkPhysicalDeviceSynchronization2FeaturesKHR {
    };

    struct VkPhysicalDeviceUnifiedImageLayoutsFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 unifiedImageLayouts;
        VkBool32 unifiedImageLayoutsVideo;
    };

    struct VkPhysicalDeviceHostImageCopyFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 hostImageCopy;
    };

    struct VkPhysicalDeviceHostImageCopyFeaturesEXT {
    };

    struct VkPhysicalDeviceHostImageCopyProperties {
        VkStructureType sType;
        void* pNext;
        uint32_t copySrcLayoutCount;
        VkImageLayout* pCopySrcLayouts;
        uint32_t copyDstLayoutCount;
        VkImageLayout* pCopyDstLayouts;
        uint8_t optimalTilingLayoutUUID[16];
        VkBool32 identicalMemoryTypeRequirements;
    };

    struct VkPhysicalDeviceHostImageCopyPropertiesEXT {
    };

    struct VkMemoryToImageCopy {
        VkStructureType sType;
        const void* pNext;
        const void* pHostPointer;
        uint32_t memoryRowLength;
        uint32_t memoryImageHeight;
        VkImageSubresourceLayers imageSubresource;
        VkOffset3D imageOffset;
        VkExtent3D imageExtent;
    };

    struct VkMemoryToImageCopyEXT {
    };

    struct VkImageToMemoryCopy {
        VkStructureType sType;
        const void* pNext;
        void* pHostPointer;
        uint32_t memoryRowLength;
        uint32_t memoryImageHeight;
        VkImageSubresourceLayers imageSubresource;
        VkOffset3D imageOffset;
        VkExtent3D imageExtent;
    };

    struct VkImageToMemoryCopyEXT {
    };

    struct VkCopyMemoryToImageInfo {
        VkStructureType sType;
        const void* pNext;
        VkHostImageCopyFlags flags;
        VkImage dstImage;
        VkImageLayout dstImageLayout;
        uint32_t regionCount;
        const VkMemoryToImageCopy* pRegions;
    };

    struct VkCopyMemoryToImageInfoEXT {
    };

    struct VkCopyImageToMemoryInfo {
        VkStructureType sType;
        const void* pNext;
        VkHostImageCopyFlags flags;
        VkImage srcImage;
        VkImageLayout srcImageLayout;
        uint32_t regionCount;
        const VkImageToMemoryCopy* pRegions;
    };

    struct VkCopyImageToMemoryInfoEXT {
    };

    struct VkCopyImageToImageInfo {
        VkStructureType sType;
        const void* pNext;
        VkHostImageCopyFlags flags;
        VkImage srcImage;
        VkImageLayout srcImageLayout;
        VkImage dstImage;
        VkImageLayout dstImageLayout;
        uint32_t regionCount;
        const VkImageCopy2* pRegions;
    };

    struct VkCopyImageToImageInfoEXT {
    };

    struct VkHostImageLayoutTransitionInfo {
        VkStructureType sType;
        const void* pNext;
        VkImage image;
        VkImageLayout oldLayout;
        VkImageLayout newLayout;
        VkImageSubresourceRange subresourceRange;
    };

    struct VkHostImageLayoutTransitionInfoEXT {
    };

    struct VkSubresourceHostMemcpySize {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize size;
    };

    struct VkSubresourceHostMemcpySizeEXT {
    };

    struct VkHostImageCopyDevicePerformanceQuery {
        VkStructureType sType;
        void* pNext;
        VkBool32 optimalDeviceAccess;
        VkBool32 identicalMemoryLayout;
    };

    struct VkHostImageCopyDevicePerformanceQueryEXT {
    };

    struct VkPhysicalDeviceVulkanSC10Properties {
        VkStructureType sType;
        void* pNext;
        VkBool32 deviceNoDynamicHostAllocations;
        VkBool32 deviceDestroyFreesMemory;
        VkBool32 commandPoolMultipleCommandBuffersRecording;
        VkBool32 commandPoolResetCommandBuffer;
        VkBool32 commandBufferSimultaneousUse;
        VkBool32 secondaryCommandBufferNullOrImagelessFramebuffer;
        VkBool32 recycleDescriptorSetMemory;
        VkBool32 recyclePipelineMemory;
        uint32_t maxRenderPassSubpasses;
        uint32_t maxRenderPassDependencies;
        uint32_t maxSubpassInputAttachments;
        uint32_t maxSubpassPreserveAttachments;
        uint32_t maxFramebufferAttachments;
        uint32_t maxDescriptorSetLayoutBindings;
        uint32_t maxQueryFaultCount;
        uint32_t maxCallbackFaultCount;
        uint32_t maxCommandPoolCommandBuffers;
        VkDeviceSize maxCommandBufferSize;
    };

    struct VkPipelinePoolSize {
        VkStructureType sType;
        const void* pNext;
        VkDeviceSize poolEntrySize;
        uint32_t poolEntryCount;
    };

    struct VkDeviceObjectReservationCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t pipelineCacheCreateInfoCount;
        const VkPipelineCacheCreateInfo* pPipelineCacheCreateInfos;
        uint32_t pipelinePoolSizeCount;
        const VkPipelinePoolSize* pPipelinePoolSizes;
        uint32_t semaphoreRequestCount;
        uint32_t commandBufferRequestCount;
        uint32_t fenceRequestCount;
        uint32_t deviceMemoryRequestCount;
        uint32_t bufferRequestCount;
        uint32_t imageRequestCount;
        uint32_t eventRequestCount;
        uint32_t queryPoolRequestCount;
        uint32_t bufferViewRequestCount;
        uint32_t imageViewRequestCount;
        uint32_t layeredImageViewRequestCount;
        uint32_t pipelineCacheRequestCount;
        uint32_t pipelineLayoutRequestCount;
        uint32_t renderPassRequestCount;
        uint32_t graphicsPipelineRequestCount;
        uint32_t computePipelineRequestCount;
        uint32_t descriptorSetLayoutRequestCount;
        uint32_t samplerRequestCount;
        uint32_t descriptorPoolRequestCount;
        uint32_t descriptorSetRequestCount;
        uint32_t framebufferRequestCount;
        uint32_t commandPoolRequestCount;
        uint32_t samplerYcbcrConversionRequestCount;
        uint32_t surfaceRequestCount;
        uint32_t swapchainRequestCount;
        uint32_t displayModeRequestCount;
        uint32_t subpassDescriptionRequestCount;
        uint32_t attachmentDescriptionRequestCount;
        uint32_t descriptorSetLayoutBindingRequestCount;
        uint32_t descriptorSetLayoutBindingLimit;
        uint32_t maxImageViewMipLevels;
        uint32_t maxImageViewArrayLayers;
        uint32_t maxLayeredImageViewMipLevels;
        uint32_t maxOcclusionQueriesPerPool;
        uint32_t maxPipelineStatisticsQueriesPerPool;
        uint32_t maxTimestampQueriesPerPool;
        uint32_t maxImmutableSamplersPerDescriptorSetLayout;
    };

    struct VkCommandPoolMemoryReservationCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkDeviceSize commandPoolReservedSize;
        uint32_t commandPoolMaxCommandBuffers;
    };

    struct VkCommandPoolMemoryConsumption {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize commandPoolAllocated;
        VkDeviceSize commandPoolReservedSize;
        VkDeviceSize commandBufferAllocated;
    };

    struct VkPhysicalDeviceVulkanSC10Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderAtomicInstructions;
    };

    struct VkPhysicalDevicePrimitivesGeneratedQueryFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 primitivesGeneratedQuery;
        VkBool32 primitivesGeneratedQueryWithRasterizerDiscard;
        VkBool32 primitivesGeneratedQueryWithNonZeroStreams;
    };

    struct VkPhysicalDeviceLegacyDitheringFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 legacyDithering;
    };

    struct VkPhysicalDeviceMultisampledRenderToSingleSampledFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 multisampledRenderToSingleSampled;
    };

    struct VkSurfaceCapabilitiesPresentId2KHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentId2Supported;
    };

    struct VkSurfaceCapabilitiesPresentWait2KHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentWait2Supported;
    };

    struct VkSubpassResolvePerformanceQueryEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 optimal;
    };

    struct VkMultisampledRenderToSingleSampledInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkBool32 multisampledRenderToSingleSampledEnable;
        VkSampleCountFlagBits rasterizationSamples;
    };

    struct VkPhysicalDevicePipelineProtectedAccessFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 pipelineProtectedAccess;
    };

    struct VkPhysicalDevicePipelineProtectedAccessFeaturesEXT {
    };

    struct VkQueueFamilyVideoPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoCodecOperationFlagsKHR videoCodecOperations;
    };

    struct VkQueueFamilyQueryResultStatusPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 queryResultStatusSupport;
    };

    struct VkVideoProfileListInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t profileCount;
        const VkVideoProfileInfoKHR* pProfiles;
    };

    struct VkPhysicalDeviceVideoFormatInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkImageUsageFlags imageUsage;
    };

    struct VkVideoFormatPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkFormat format;
        VkComponentMapping componentMapping;
        VkImageCreateFlags imageCreateFlags;
        VkImageType imageType;
        VkImageTiling imageTiling;
        VkImageUsageFlags imageUsageFlags;
    };

    struct VkVideoEncodeQuantizationMapCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        VkExtent2D maxQuantizationMapExtent;
    };

    struct VkVideoEncodeH264QuantizationMapCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        int32_t minQpDelta;
        int32_t maxQpDelta;
    };

    struct VkVideoEncodeH265QuantizationMapCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        int32_t minQpDelta;
        int32_t maxQpDelta;
    };

    struct VkVideoEncodeAV1QuantizationMapCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        int32_t minQIndexDelta;
        int32_t maxQIndexDelta;
    };

    struct VkVideoFormatQuantizationMapPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkExtent2D quantizationMapTexelSize;
    };

    struct VkVideoFormatH265QuantizationMapPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeH265CtbSizeFlagsKHR compatibleCtbSizes;
    };

    struct VkVideoFormatAV1QuantizationMapPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeAV1SuperblockSizeFlagsKHR compatibleSuperblockSizes;
    };

    struct VkVideoProfileInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoCodecOperationFlagBitsKHR videoCodecOperation;
        VkVideoChromaSubsamplingFlagsKHR chromaSubsampling;
        VkVideoComponentBitDepthFlagsKHR lumaBitDepth;
        VkVideoComponentBitDepthFlagsKHR chromaBitDepth;
    };

    struct VkVideoCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoCapabilityFlagsKHR flags;
        VkDeviceSize minBitstreamBufferOffsetAlignment;
        VkDeviceSize minBitstreamBufferSizeAlignment;
        VkExtent2D pictureAccessGranularity;
        VkExtent2D minCodedExtent;
        VkExtent2D maxCodedExtent;
        uint32_t maxDpbSlots;
        uint32_t maxActiveReferencePictures;
        VkExtensionProperties stdHeaderVersion;
    };

    struct VkVideoSessionMemoryRequirementsKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t memoryBindIndex;
        VkMemoryRequirements memoryRequirements;
    };

    struct VkBindVideoSessionMemoryInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t memoryBindIndex;
        VkDeviceMemory memory;
        VkDeviceSize memoryOffset;
        VkDeviceSize memorySize;
    };

    struct VkVideoPictureResourceInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkOffset2D codedOffset;
        VkExtent2D codedExtent;
        uint32_t baseArrayLayer;
        VkImageView imageViewBinding;
    };

    struct VkVideoReferenceSlotInfoKHR {
        VkStructureType sType;
        const void* pNext;
        int32_t slotIndex;
        const VkVideoPictureResourceInfoKHR* pPictureResource;
    };

    struct VkVideoDecodeCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoDecodeCapabilityFlagsKHR flags;
    };

    struct VkVideoDecodeUsageInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoDecodeUsageFlagsKHR videoUsageHints;
    };

    struct VkVideoDecodeInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoDecodeFlagsKHR flags;
        VkBuffer srcBuffer;
        VkDeviceSize srcBufferOffset;
        VkDeviceSize srcBufferRange;
        VkVideoPictureResourceInfoKHR dstPictureResource;
        const VkVideoReferenceSlotInfoKHR* pSetupReferenceSlot;
        uint32_t referenceSlotCount;
        const VkVideoReferenceSlotInfoKHR* pReferenceSlots;
    };

    struct VkPhysicalDeviceVideoMaintenance1FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 videoMaintenance1;
    };

    struct VkPhysicalDeviceVideoMaintenance2FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 videoMaintenance2;
    };

    struct VkVideoInlineQueryInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkQueryPool queryPool;
        uint32_t firstQuery;
        uint32_t queryCount;
    };

    struct VkVideoDecodeH264ProfileInfoKHR {
        VkStructureType sType;
        const void* pNext;
        StdVideoH264ProfileIdc stdProfileIdc;
        VkVideoDecodeH264PictureLayoutFlagBitsKHR pictureLayout;
    };

    struct VkVideoDecodeH264CapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        StdVideoH264LevelIdc maxLevelIdc;
        VkOffset2D fieldOffsetGranularity;
    };

    struct VkVideoDecodeH264SessionParametersAddInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t stdSPSCount;
        const StdVideoH264SequenceParameterSet* pStdSPSs;
        uint32_t stdPPSCount;
        const StdVideoH264PictureParameterSet* pStdPPSs;
    };

    struct VkVideoDecodeH264SessionParametersCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t maxStdSPSCount;
        uint32_t maxStdPPSCount;
        const VkVideoDecodeH264SessionParametersAddInfoKHR* pParametersAddInfo;
    };

    struct VkVideoDecodeH264InlineSessionParametersInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoH264SequenceParameterSet* pStdSPS;
        const StdVideoH264PictureParameterSet* pStdPPS;
    };

    struct VkVideoDecodeH264PictureInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoDecodeH264PictureInfo* pStdPictureInfo;
        uint32_t sliceCount;
        const uint32_t* pSliceOffsets;
    };

    struct VkVideoDecodeH264DpbSlotInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoDecodeH264ReferenceInfo* pStdReferenceInfo;
    };

    struct VkVideoDecodeH265ProfileInfoKHR {
        VkStructureType sType;
        const void* pNext;
        StdVideoH265ProfileIdc stdProfileIdc;
    };

    struct VkVideoDecodeH265CapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        StdVideoH265LevelIdc maxLevelIdc;
    };

    struct VkVideoDecodeH265SessionParametersAddInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t stdVPSCount;
        const StdVideoH265VideoParameterSet* pStdVPSs;
        uint32_t stdSPSCount;
        const StdVideoH265SequenceParameterSet* pStdSPSs;
        uint32_t stdPPSCount;
        const StdVideoH265PictureParameterSet* pStdPPSs;
    };

    struct VkVideoDecodeH265SessionParametersCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t maxStdVPSCount;
        uint32_t maxStdSPSCount;
        uint32_t maxStdPPSCount;
        const VkVideoDecodeH265SessionParametersAddInfoKHR* pParametersAddInfo;
    };

    struct VkVideoDecodeH265InlineSessionParametersInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoH265VideoParameterSet* pStdVPS;
        const StdVideoH265SequenceParameterSet* pStdSPS;
        const StdVideoH265PictureParameterSet* pStdPPS;
    };

    struct VkVideoDecodeH265PictureInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoDecodeH265PictureInfo* pStdPictureInfo;
        uint32_t sliceSegmentCount;
        const uint32_t* pSliceSegmentOffsets;
    };

    struct VkVideoDecodeH265DpbSlotInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoDecodeH265ReferenceInfo* pStdReferenceInfo;
    };

    struct VkPhysicalDeviceVideoDecodeVP9FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 videoDecodeVP9;
    };

    struct VkVideoDecodeVP9ProfileInfoKHR {
        VkStructureType sType;
        const void* pNext;
        StdVideoVP9Profile stdProfile;
    };

    struct VkVideoDecodeVP9CapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        StdVideoVP9Level maxLevel;
    };

    struct VkVideoDecodeVP9PictureInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoDecodeVP9PictureInfo* pStdPictureInfo;
        int32_t referenceNameSlotIndices[3];
        uint32_t uncompressedHeaderOffset;
        uint32_t compressedHeaderOffset;
        uint32_t tilesOffset;
    };

    struct VkVideoDecodeAV1ProfileInfoKHR {
        VkStructureType sType;
        const void* pNext;
        StdVideoAV1Profile stdProfile;
        VkBool32 filmGrainSupport;
    };

    struct VkVideoDecodeAV1CapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        StdVideoAV1Level maxLevel;
    };

    struct VkVideoDecodeAV1SessionParametersCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoAV1SequenceHeader* pStdSequenceHeader;
    };

    struct VkVideoDecodeAV1InlineSessionParametersInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoAV1SequenceHeader* pStdSequenceHeader;
    };

    struct VkVideoDecodeAV1PictureInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoDecodeAV1PictureInfo* pStdPictureInfo;
        int32_t referenceNameSlotIndices[7];
        uint32_t frameHeaderOffset;
        uint32_t tileCount;
        const uint32_t* pTileOffsets;
        const uint32_t* pTileSizes;
    };

    struct VkVideoDecodeAV1DpbSlotInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoDecodeAV1ReferenceInfo* pStdReferenceInfo;
    };

    struct VkVideoSessionCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t queueFamilyIndex;
        VkVideoSessionCreateFlagsKHR flags;
        const VkVideoProfileInfoKHR* pVideoProfile;
        VkFormat pictureFormat;
        VkExtent2D maxCodedExtent;
        VkFormat referencePictureFormat;
        uint32_t maxDpbSlots;
        uint32_t maxActiveReferencePictures;
        const VkExtensionProperties* pStdHeaderVersion;
    };

    struct VkVideoSessionParametersCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoSessionParametersCreateFlagsKHR flags;
        VkVideoSessionParametersKHR videoSessionParametersTemplate;
        VkVideoSessionKHR videoSession;
    };

    struct VkVideoSessionParametersUpdateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t updateSequenceCount;
    };

    struct VkVideoEncodeSessionParametersGetInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoSessionParametersKHR videoSessionParameters;
    };

    struct VkVideoEncodeSessionParametersFeedbackInfoKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 hasOverrides;
    };

    struct VkVideoBeginCodingInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoBeginCodingFlagsKHR flags;
        VkVideoSessionKHR videoSession;
        VkVideoSessionParametersKHR videoSessionParameters;
        uint32_t referenceSlotCount;
        const VkVideoReferenceSlotInfoKHR* pReferenceSlots;
    };

    struct VkVideoEndCodingInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoEndCodingFlagsKHR flags;
    };

    struct VkVideoCodingControlInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoCodingControlFlagsKHR flags;
    };

    struct VkVideoEncodeUsageInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoEncodeUsageFlagsKHR videoUsageHints;
        VkVideoEncodeContentFlagsKHR videoContentHints;
        VkVideoEncodeTuningModeKHR tuningMode;
    };

    struct VkVideoEncodeInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoEncodeFlagsKHR flags;
        VkBuffer dstBuffer;
        VkDeviceSize dstBufferOffset;
        VkDeviceSize dstBufferRange;
        VkVideoPictureResourceInfoKHR srcPictureResource;
        const VkVideoReferenceSlotInfoKHR* pSetupReferenceSlot;
        uint32_t referenceSlotCount;
        const VkVideoReferenceSlotInfoKHR* pReferenceSlots;
        uint32_t precedingExternallyEncodedBytes;
    };

    struct VkVideoEncodeQuantizationMapInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkImageView quantizationMap;
        VkExtent2D quantizationMapExtent;
    };

    struct VkVideoEncodeQuantizationMapSessionParametersCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkExtent2D quantizationMapTexelSize;
    };

    struct VkPhysicalDeviceVideoEncodeQuantizationMapFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 videoEncodeQuantizationMap;
    };

    struct VkQueryPoolVideoEncodeFeedbackCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoEncodeFeedbackFlagsKHR encodeFeedbackFlags;
    };

    struct VkVideoEncodeQualityLevelInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t qualityLevel;
    };

    struct VkPhysicalDeviceVideoEncodeQualityLevelInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const VkVideoProfileInfoKHR* pVideoProfile;
        uint32_t qualityLevel;
    };

    struct VkVideoEncodeQualityLevelPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeRateControlModeFlagBitsKHR preferredRateControlMode;
        uint32_t preferredRateControlLayerCount;
    };

    struct VkVideoEncodeRateControlInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoEncodeRateControlFlagsKHR flags;
        VkVideoEncodeRateControlModeFlagBitsKHR rateControlMode;
        uint32_t layerCount;
        const VkVideoEncodeRateControlLayerInfoKHR* pLayers;
        uint32_t virtualBufferSizeInMs;
        uint32_t initialVirtualBufferSizeInMs;
    };

    struct VkVideoEncodeRateControlLayerInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint64_t averageBitrate;
        uint64_t maxBitrate;
        uint32_t frameRateNumerator;
        uint32_t frameRateDenominator;
    };

    struct VkVideoEncodeCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeCapabilityFlagsKHR flags;
        VkVideoEncodeRateControlModeFlagsKHR rateControlModes;
        uint32_t maxRateControlLayers;
        uint64_t maxBitrate;
        uint32_t maxQualityLevels;
        VkExtent2D encodeInputPictureGranularity;
        VkVideoEncodeFeedbackFlagsKHR supportedEncodeFeedbackFlags;
    };

    struct VkVideoEncodeH264CapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeH264CapabilityFlagsKHR flags;
        StdVideoH264LevelIdc maxLevelIdc;
        uint32_t maxSliceCount;
        uint32_t maxPPictureL0ReferenceCount;
        uint32_t maxBPictureL0ReferenceCount;
        uint32_t maxL1ReferenceCount;
        uint32_t maxTemporalLayerCount;
        VkBool32 expectDyadicTemporalLayerPattern;
        int32_t minQp;
        int32_t maxQp;
        VkBool32 prefersGopRemainingFrames;
        VkBool32 requiresGopRemainingFrames;
        VkVideoEncodeH264StdFlagsKHR stdSyntaxFlags;
    };

    struct VkVideoEncodeH264QpKHR {
        int32_t qpI;
        int32_t qpP;
        int32_t qpB;
    };

    struct VkVideoEncodeH264QualityLevelPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeH264RateControlFlagsKHR preferredRateControlFlags;
        uint32_t preferredGopFrameCount;
        uint32_t preferredIdrPeriod;
        uint32_t preferredConsecutiveBFrameCount;
        uint32_t preferredTemporalLayerCount;
        VkVideoEncodeH264QpKHR preferredConstantQp;
        uint32_t preferredMaxL0ReferenceCount;
        uint32_t preferredMaxL1ReferenceCount;
        VkBool32 preferredStdEntropyCodingModeFlag;
    };

    struct VkVideoEncodeH264SessionCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 useMaxLevelIdc;
        StdVideoH264LevelIdc maxLevelIdc;
    };

    struct VkVideoEncodeH264SessionParametersAddInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t stdSPSCount;
        const StdVideoH264SequenceParameterSet* pStdSPSs;
        uint32_t stdPPSCount;
        const StdVideoH264PictureParameterSet* pStdPPSs;
    };

    struct VkVideoEncodeH264SessionParametersCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t maxStdSPSCount;
        uint32_t maxStdPPSCount;
        const VkVideoEncodeH264SessionParametersAddInfoKHR* pParametersAddInfo;
    };

    struct VkVideoEncodeH264SessionParametersGetInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 writeStdSPS;
        VkBool32 writeStdPPS;
        uint32_t stdSPSId;
        uint32_t stdPPSId;
    };

    struct VkVideoEncodeH264SessionParametersFeedbackInfoKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 hasStdSPSOverrides;
        VkBool32 hasStdPPSOverrides;
    };

    struct VkVideoEncodeH264DpbSlotInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoEncodeH264ReferenceInfo* pStdReferenceInfo;
    };

    struct VkVideoEncodeH264PictureInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t naluSliceEntryCount;
        const VkVideoEncodeH264NaluSliceInfoKHR* pNaluSliceEntries;
        const StdVideoEncodeH264PictureInfo* pStdPictureInfo;
        VkBool32 generatePrefixNalu;
    };

    struct VkVideoEncodeH264ProfileInfoKHR {
        VkStructureType sType;
        const void* pNext;
        StdVideoH264ProfileIdc stdProfileIdc;
    };

    struct VkVideoEncodeH264NaluSliceInfoKHR {
        VkStructureType sType;
        const void* pNext;
        int32_t constantQp;
        const StdVideoEncodeH264SliceHeader* pStdSliceHeader;
    };

    struct VkVideoEncodeH264RateControlInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoEncodeH264RateControlFlagsKHR flags;
        uint32_t gopFrameCount;
        uint32_t idrPeriod;
        uint32_t consecutiveBFrameCount;
        uint32_t temporalLayerCount;
    };

    struct VkVideoEncodeH264FrameSizeKHR {
        uint32_t frameISize;
        uint32_t framePSize;
        uint32_t frameBSize;
    };

    struct VkVideoEncodeH264GopRemainingFrameInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 useGopRemainingFrames;
        uint32_t gopRemainingI;
        uint32_t gopRemainingP;
        uint32_t gopRemainingB;
    };

    struct VkVideoEncodeH264RateControlLayerInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 useMinQp;
        VkVideoEncodeH264QpKHR minQp;
        VkBool32 useMaxQp;
        VkVideoEncodeH264QpKHR maxQp;
        VkBool32 useMaxFrameSize;
        VkVideoEncodeH264FrameSizeKHR maxFrameSize;
    };

    struct VkVideoEncodeH265CapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeH265CapabilityFlagsKHR flags;
        StdVideoH265LevelIdc maxLevelIdc;
        uint32_t maxSliceSegmentCount;
        VkExtent2D maxTiles;
        VkVideoEncodeH265CtbSizeFlagsKHR ctbSizes;
        VkVideoEncodeH265TransformBlockSizeFlagsKHR transformBlockSizes;
        uint32_t maxPPictureL0ReferenceCount;
        uint32_t maxBPictureL0ReferenceCount;
        uint32_t maxL1ReferenceCount;
        uint32_t maxSubLayerCount;
        VkBool32 expectDyadicTemporalSubLayerPattern;
        int32_t minQp;
        int32_t maxQp;
        VkBool32 prefersGopRemainingFrames;
        VkBool32 requiresGopRemainingFrames;
        VkVideoEncodeH265StdFlagsKHR stdSyntaxFlags;
    };

    struct VkVideoEncodeH265QpKHR {
        int32_t qpI;
        int32_t qpP;
        int32_t qpB;
    };

    struct VkVideoEncodeH265QualityLevelPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeH265RateControlFlagsKHR preferredRateControlFlags;
        uint32_t preferredGopFrameCount;
        uint32_t preferredIdrPeriod;
        uint32_t preferredConsecutiveBFrameCount;
        uint32_t preferredSubLayerCount;
        VkVideoEncodeH265QpKHR preferredConstantQp;
        uint32_t preferredMaxL0ReferenceCount;
        uint32_t preferredMaxL1ReferenceCount;
    };

    struct VkVideoEncodeH265SessionCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 useMaxLevelIdc;
        StdVideoH265LevelIdc maxLevelIdc;
    };

    struct VkVideoEncodeH265SessionParametersAddInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t stdVPSCount;
        const StdVideoH265VideoParameterSet* pStdVPSs;
        uint32_t stdSPSCount;
        const StdVideoH265SequenceParameterSet* pStdSPSs;
        uint32_t stdPPSCount;
        const StdVideoH265PictureParameterSet* pStdPPSs;
    };

    struct VkVideoEncodeH265SessionParametersCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t maxStdVPSCount;
        uint32_t maxStdSPSCount;
        uint32_t maxStdPPSCount;
        const VkVideoEncodeH265SessionParametersAddInfoKHR* pParametersAddInfo;
    };

    struct VkVideoEncodeH265SessionParametersGetInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 writeStdVPS;
        VkBool32 writeStdSPS;
        VkBool32 writeStdPPS;
        uint32_t stdVPSId;
        uint32_t stdSPSId;
        uint32_t stdPPSId;
    };

    struct VkVideoEncodeH265SessionParametersFeedbackInfoKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 hasStdVPSOverrides;
        VkBool32 hasStdSPSOverrides;
        VkBool32 hasStdPPSOverrides;
    };

    struct VkVideoEncodeH265PictureInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t naluSliceSegmentEntryCount;
        const VkVideoEncodeH265NaluSliceSegmentInfoKHR* pNaluSliceSegmentEntries;
        const StdVideoEncodeH265PictureInfo* pStdPictureInfo;
    };

    struct VkVideoEncodeH265NaluSliceSegmentInfoKHR {
        VkStructureType sType;
        const void* pNext;
        int32_t constantQp;
        const StdVideoEncodeH265SliceSegmentHeader* pStdSliceSegmentHeader;
    };

    struct VkVideoEncodeH265RateControlInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoEncodeH265RateControlFlagsKHR flags;
        uint32_t gopFrameCount;
        uint32_t idrPeriod;
        uint32_t consecutiveBFrameCount;
        uint32_t subLayerCount;
    };

    struct VkVideoEncodeH265FrameSizeKHR {
        uint32_t frameISize;
        uint32_t framePSize;
        uint32_t frameBSize;
    };

    struct VkVideoEncodeH265GopRemainingFrameInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 useGopRemainingFrames;
        uint32_t gopRemainingI;
        uint32_t gopRemainingP;
        uint32_t gopRemainingB;
    };

    struct VkVideoEncodeH265RateControlLayerInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 useMinQp;
        VkVideoEncodeH265QpKHR minQp;
        VkBool32 useMaxQp;
        VkVideoEncodeH265QpKHR maxQp;
        VkBool32 useMaxFrameSize;
        VkVideoEncodeH265FrameSizeKHR maxFrameSize;
    };

    struct VkVideoEncodeH265ProfileInfoKHR {
        VkStructureType sType;
        const void* pNext;
        StdVideoH265ProfileIdc stdProfileIdc;
    };

    struct VkVideoEncodeH265DpbSlotInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoEncodeH265ReferenceInfo* pStdReferenceInfo;
    };

    struct VkVideoEncodeAV1CapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeAV1CapabilityFlagsKHR flags;
        StdVideoAV1Level maxLevel;
        VkExtent2D codedPictureAlignment;
        VkExtent2D maxTiles;
        VkExtent2D minTileSize;
        VkExtent2D maxTileSize;
        VkVideoEncodeAV1SuperblockSizeFlagsKHR superblockSizes;
        uint32_t maxSingleReferenceCount;
        uint32_t singleReferenceNameMask;
        uint32_t maxUnidirectionalCompoundReferenceCount;
        uint32_t maxUnidirectionalCompoundGroup1ReferenceCount;
        uint32_t unidirectionalCompoundReferenceNameMask;
        uint32_t maxBidirectionalCompoundReferenceCount;
        uint32_t maxBidirectionalCompoundGroup1ReferenceCount;
        uint32_t maxBidirectionalCompoundGroup2ReferenceCount;
        uint32_t bidirectionalCompoundReferenceNameMask;
        uint32_t maxTemporalLayerCount;
        uint32_t maxSpatialLayerCount;
        uint32_t maxOperatingPoints;
        uint32_t minQIndex;
        uint32_t maxQIndex;
        VkBool32 prefersGopRemainingFrames;
        VkBool32 requiresGopRemainingFrames;
        VkVideoEncodeAV1StdFlagsKHR stdSyntaxFlags;
    };

    struct VkVideoEncodeAV1QIndexKHR {
        uint32_t intraQIndex;
        uint32_t predictiveQIndex;
        uint32_t bipredictiveQIndex;
    };

    struct VkVideoEncodeAV1QualityLevelPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeAV1RateControlFlagsKHR preferredRateControlFlags;
        uint32_t preferredGopFrameCount;
        uint32_t preferredKeyFramePeriod;
        uint32_t preferredConsecutiveBipredictiveFrameCount;
        uint32_t preferredTemporalLayerCount;
        VkVideoEncodeAV1QIndexKHR preferredConstantQIndex;
        uint32_t preferredMaxSingleReferenceCount;
        uint32_t preferredSingleReferenceNameMask;
        uint32_t preferredMaxUnidirectionalCompoundReferenceCount;
        uint32_t preferredMaxUnidirectionalCompoundGroup1ReferenceCount;
        uint32_t preferredUnidirectionalCompoundReferenceNameMask;
        uint32_t preferredMaxBidirectionalCompoundReferenceCount;
        uint32_t preferredMaxBidirectionalCompoundGroup1ReferenceCount;
        uint32_t preferredMaxBidirectionalCompoundGroup2ReferenceCount;
        uint32_t preferredBidirectionalCompoundReferenceNameMask;
    };

    struct VkPhysicalDeviceVideoEncodeAV1FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 videoEncodeAV1;
    };

    struct VkVideoEncodeAV1SessionCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 useMaxLevel;
        StdVideoAV1Level maxLevel;
    };

    struct VkVideoEncodeAV1SessionParametersCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoAV1SequenceHeader* pStdSequenceHeader;
        const StdVideoEncodeAV1DecoderModelInfo* pStdDecoderModelInfo;
        uint32_t stdOperatingPointCount;
        const StdVideoEncodeAV1OperatingPointInfo* pStdOperatingPoints;
    };

    struct VkVideoEncodeAV1DpbSlotInfoKHR {
        VkStructureType sType;
        const void* pNext;
        const StdVideoEncodeAV1ReferenceInfo* pStdReferenceInfo;
    };

    struct VkVideoEncodeAV1PictureInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoEncodeAV1PredictionModeKHR predictionMode;
        VkVideoEncodeAV1RateControlGroupKHR rateControlGroup;
        uint32_t constantQIndex;
        const StdVideoEncodeAV1PictureInfo* pStdPictureInfo;
        int32_t referenceNameSlotIndices[7];
        VkBool32 primaryReferenceCdfOnly;
        VkBool32 generateObuExtensionHeader;
    };

    struct VkVideoEncodeAV1ProfileInfoKHR {
        VkStructureType sType;
        const void* pNext;
        StdVideoAV1Profile stdProfile;
    };

    struct VkVideoEncodeAV1RateControlInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoEncodeAV1RateControlFlagsKHR flags;
        uint32_t gopFrameCount;
        uint32_t keyFramePeriod;
        uint32_t consecutiveBipredictiveFrameCount;
        uint32_t temporalLayerCount;
    };

    struct VkVideoEncodeAV1FrameSizeKHR {
        uint32_t intraFrameSize;
        uint32_t predictiveFrameSize;
        uint32_t bipredictiveFrameSize;
    };

    struct VkVideoEncodeAV1GopRemainingFrameInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 useGopRemainingFrames;
        uint32_t gopRemainingIntra;
        uint32_t gopRemainingPredictive;
        uint32_t gopRemainingBipredictive;
    };

    struct VkVideoEncodeAV1RateControlLayerInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 useMinQIndex;
        VkVideoEncodeAV1QIndexKHR minQIndex;
        VkBool32 useMaxQIndex;
        VkVideoEncodeAV1QIndexKHR maxQIndex;
        VkBool32 useMaxFrameSize;
        VkVideoEncodeAV1FrameSizeKHR maxFrameSize;
    };

    struct VkPhysicalDeviceInheritedViewportScissorFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 inheritedViewportScissor2D;
    };

    struct VkCommandBufferInheritanceViewportScissorInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkBool32 viewportScissor2D;
        uint32_t viewportDepthCount;
        const VkViewport* pViewportDepths;
    };

    struct VkPhysicalDeviceYcbcr2Plane444FormatsFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 ycbcr2plane444Formats;
    };

    struct VkPhysicalDeviceProvokingVertexFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 provokingVertexLast;
        VkBool32 transformFeedbackPreservesProvokingVertex;
    };

    struct VkPhysicalDeviceProvokingVertexPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 provokingVertexModePerPipeline;
        VkBool32 transformFeedbackPreservesTriangleFanProvokingVertex;
    };

    struct VkPipelineRasterizationProvokingVertexStateCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkProvokingVertexModeEXT provokingVertexMode;
    };

    struct VkVideoEncodeIntraRefreshCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeIntraRefreshModeFlagsKHR intraRefreshModes;
        uint32_t maxIntraRefreshCycleDuration;
        uint32_t maxIntraRefreshActiveReferencePictures;
        VkBool32 partitionIndependentIntraRefreshRegions;
        VkBool32 nonRectangularIntraRefreshRegions;
    };

    struct VkVideoEncodeSessionIntraRefreshCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkVideoEncodeIntraRefreshModeFlagBitsKHR intraRefreshMode;
    };

    struct VkVideoEncodeIntraRefreshInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t intraRefreshCycleDuration;
        uint32_t intraRefreshIndex;
    };

    struct VkVideoReferenceIntraRefreshInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t dirtyIntraRefreshRegions;
    };

    struct VkPhysicalDeviceVideoEncodeIntraRefreshFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 videoEncodeIntraRefresh;
    };

    struct VkCuModuleCreateInfoNVX {
        VkStructureType sType;
        const void* pNext;
        size_t dataSize;
        const void* pData;
    };

    struct VkCuModuleTexturingModeCreateInfoNVX {
        VkStructureType sType;
        const void* pNext;
        VkBool32 use64bitTexturing;
    };

    struct VkCuFunctionCreateInfoNVX {
        VkStructureType sType;
        const void* pNext;
        VkCuModuleNVX module;
        const char* pName;
    };

    struct VkCuLaunchInfoNVX {
        VkStructureType sType;
        const void* pNext;
        VkCuFunctionNVX function;
        uint32_t gridDimX;
        uint32_t gridDimY;
        uint32_t gridDimZ;
        uint32_t blockDimX;
        uint32_t blockDimY;
        uint32_t blockDimZ;
        uint32_t sharedMemBytes;
        size_t paramCount;
        const void* const * pParams;
        size_t extraCount;
        const void* const * pExtras;
    };

    struct VkPhysicalDeviceDescriptorBufferFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 descriptorBuffer;
        VkBool32 descriptorBufferCaptureReplay;
        VkBool32 descriptorBufferImageLayoutIgnored;
        VkBool32 descriptorBufferPushDescriptors;
    };

    struct VkPhysicalDeviceDescriptorBufferPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 combinedImageSamplerDescriptorSingleArray;
        VkBool32 bufferlessPushDescriptors;
        VkBool32 allowSamplerImageViewPostSubmitCreation;
        VkDeviceSize descriptorBufferOffsetAlignment;
        uint32_t maxDescriptorBufferBindings;
        uint32_t maxResourceDescriptorBufferBindings;
        uint32_t maxSamplerDescriptorBufferBindings;
        uint32_t maxEmbeddedImmutableSamplerBindings;
        uint32_t maxEmbeddedImmutableSamplers;
        size_t bufferCaptureReplayDescriptorDataSize;
        size_t imageCaptureReplayDescriptorDataSize;
        size_t imageViewCaptureReplayDescriptorDataSize;
        size_t samplerCaptureReplayDescriptorDataSize;
        size_t accelerationStructureCaptureReplayDescriptorDataSize;
        size_t samplerDescriptorSize;
        size_t combinedImageSamplerDescriptorSize;
        size_t sampledImageDescriptorSize;
        size_t storageImageDescriptorSize;
        size_t uniformTexelBufferDescriptorSize;
        size_t robustUniformTexelBufferDescriptorSize;
        size_t storageTexelBufferDescriptorSize;
        size_t robustStorageTexelBufferDescriptorSize;
        size_t uniformBufferDescriptorSize;
        size_t robustUniformBufferDescriptorSize;
        size_t storageBufferDescriptorSize;
        size_t robustStorageBufferDescriptorSize;
        size_t inputAttachmentDescriptorSize;
        size_t accelerationStructureDescriptorSize;
        VkDeviceSize maxSamplerDescriptorBufferRange;
        VkDeviceSize maxResourceDescriptorBufferRange;
        VkDeviceSize samplerDescriptorBufferAddressSpaceSize;
        VkDeviceSize resourceDescriptorBufferAddressSpaceSize;
        VkDeviceSize descriptorBufferAddressSpaceSize;
    };

    struct VkPhysicalDeviceDescriptorBufferDensityMapPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        size_t combinedImageSamplerDensityMapDescriptorSize;
    };

    struct VkDescriptorAddressInfoEXT {
        VkStructureType sType;
        void* pNext;
        VkDeviceAddress address;
        VkDeviceSize range;
        VkFormat format;
    };

    struct VkDescriptorBufferBindingInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDeviceAddress address;
        VkBufferUsageFlags usage;
    };

    struct VkDescriptorBufferBindingPushDescriptorBufferHandleEXT {
        VkStructureType sType;
        const void* pNext;
        VkBuffer buffer;
    };

    union VkDescriptorDataEXT {
        const VkSampler* pSampler;
        const VkDescriptorImageInfo* pCombinedImageSampler;
        const VkDescriptorImageInfo* pInputAttachmentImage;
        const VkDescriptorImageInfo* pSampledImage;
        const VkDescriptorImageInfo* pStorageImage;
        const VkDescriptorAddressInfoEXT* pUniformTexelBuffer;
        const VkDescriptorAddressInfoEXT* pStorageTexelBuffer;
        const VkDescriptorAddressInfoEXT* pUniformBuffer;
        const VkDescriptorAddressInfoEXT* pStorageBuffer;
        VkDeviceAddress accelerationStructure;
    };

    struct VkDescriptorGetInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDescriptorType type;
        VkDescriptorDataEXT data;
    };

    struct VkBufferCaptureDescriptorDataInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkBuffer buffer;
    };

    struct VkImageCaptureDescriptorDataInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkImage image;
    };

    struct VkImageViewCaptureDescriptorDataInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkImageView imageView;
    };

    struct VkSamplerCaptureDescriptorDataInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkSampler sampler;
    };

    struct VkAccelerationStructureCaptureDescriptorDataInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkAccelerationStructureKHR accelerationStructure;
        VkAccelerationStructureNV accelerationStructureNV;
    };

    struct VkOpaqueCaptureDescriptorDataCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        const void* opaqueCaptureDescriptorData;
    };

    struct VkPhysicalDeviceShaderIntegerDotProductFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderIntegerDotProduct;
    };

    struct VkPhysicalDeviceShaderIntegerDotProductFeaturesKHR {
    };

    struct VkPhysicalDeviceShaderIntegerDotProductProperties {
        VkStructureType sType;
        void* pNext;
        VkBool32 integerDotProduct8BitUnsignedAccelerated;
        VkBool32 integerDotProduct8BitSignedAccelerated;
        VkBool32 integerDotProduct8BitMixedSignednessAccelerated;
        VkBool32 integerDotProduct4x8BitPackedUnsignedAccelerated;
        VkBool32 integerDotProduct4x8BitPackedSignedAccelerated;
        VkBool32 integerDotProduct4x8BitPackedMixedSignednessAccelerated;
        VkBool32 integerDotProduct16BitUnsignedAccelerated;
        VkBool32 integerDotProduct16BitSignedAccelerated;
        VkBool32 integerDotProduct16BitMixedSignednessAccelerated;
        VkBool32 integerDotProduct32BitUnsignedAccelerated;
        VkBool32 integerDotProduct32BitSignedAccelerated;
        VkBool32 integerDotProduct32BitMixedSignednessAccelerated;
        VkBool32 integerDotProduct64BitUnsignedAccelerated;
        VkBool32 integerDotProduct64BitSignedAccelerated;
        VkBool32 integerDotProduct64BitMixedSignednessAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating8BitUnsignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating8BitSignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating8BitMixedSignednessAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating4x8BitPackedUnsignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating4x8BitPackedSignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating4x8BitPackedMixedSignednessAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating16BitUnsignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating16BitSignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating16BitMixedSignednessAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating32BitUnsignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating32BitSignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating32BitMixedSignednessAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating64BitUnsignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating64BitSignedAccelerated;
        VkBool32 integerDotProductAccumulatingSaturating64BitMixedSignednessAccelerated;
    };

    struct VkPhysicalDeviceShaderIntegerDotProductPropertiesKHR {
    };

    struct VkPhysicalDeviceDrmPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 hasPrimary;
        VkBool32 hasRender;
        int64_t primaryMajor;
        int64_t primaryMinor;
        int64_t renderMajor;
        int64_t renderMinor;
    };

    struct VkPhysicalDeviceFragmentShaderBarycentricFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 fragmentShaderBarycentric;
    };

    struct VkPhysicalDeviceFragmentShaderBarycentricPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 triStripVertexOrderIndependentOfProvokingVertex;
    };

    struct VkPhysicalDeviceShaderFmaFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderFmaFloat16;
        VkBool32 shaderFmaFloat32;
        VkBool32 shaderFmaFloat64;
    };

    struct VkPhysicalDeviceRayTracingMotionBlurFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 rayTracingMotionBlur;
        VkBool32 rayTracingMotionBlurPipelineTraceRaysIndirect;
    };

    struct VkPhysicalDeviceRayTracingValidationFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 rayTracingValidation;
    };

    struct VkPhysicalDeviceRayTracingLinearSweptSpheresFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 spheres;
        VkBool32 linearSweptSpheres;
    };

    struct VkAccelerationStructureGeometryMotionTrianglesDataNV {
        VkStructureType sType;
        const void* pNext;
        VkDeviceOrHostAddressConstKHR vertexData;
    };

    struct VkAccelerationStructureMotionInfoNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t maxInstances;
        VkAccelerationStructureMotionInfoFlagsNV flags;
    };

    struct VkSRTDataNV {
        float sx;
        float a;
        float b;
        float pvx;
        float sy;
        float c;
        float pvy;
        float sz;
        float pvz;
        float qx;
        float qy;
        float qz;
        float qw;
        float tx;
        float ty;
        float tz;
    };

    struct VkAccelerationStructureSRTMotionInstanceNV {
        VkSRTDataNV transformT0;
        VkSRTDataNV transformT1;
        uint32_t instanceCustomIndex;
        uint32_t mask;
        uint32_t instanceShaderBindingTableRecordOffset;
        VkGeometryInstanceFlagsKHR flags;
        uint64_t accelerationStructureReference;
    };

    struct VkAccelerationStructureMatrixMotionInstanceNV {
        VkTransformMatrixKHR transformT0;
        VkTransformMatrixKHR transformT1;
        uint32_t instanceCustomIndex;
        uint32_t mask;
        uint32_t instanceShaderBindingTableRecordOffset;
        VkGeometryInstanceFlagsKHR flags;
        uint64_t accelerationStructureReference;
    };

    union VkAccelerationStructureMotionInstanceDataNV {
        VkAccelerationStructureInstanceKHR staticInstance;
        VkAccelerationStructureMatrixMotionInstanceNV matrixMotionInstance;
        VkAccelerationStructureSRTMotionInstanceNV srtMotionInstance;
    };

    struct VkAccelerationStructureMotionInstanceNV {
        VkAccelerationStructureMotionInstanceTypeNV type;
        VkAccelerationStructureMotionInstanceFlagsNV flags;
        VkAccelerationStructureMotionInstanceDataNV data;
    };

    struct VkMemoryGetRemoteAddressInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
        VkExternalMemoryHandleTypeFlagBits handleType;
    };

    struct VkImportMemoryBufferCollectionFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        VkBufferCollectionFUCHSIA collection;
        uint32_t index;
    };

    struct VkBufferCollectionImageCreateInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        VkBufferCollectionFUCHSIA collection;
        uint32_t index;
    };

    struct VkBufferCollectionBufferCreateInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        VkBufferCollectionFUCHSIA collection;
        uint32_t index;
    };

    struct VkBufferCollectionCreateInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        zx_handle_t collectionToken;
    };

    struct VkSysmemColorSpaceFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        uint32_t colorSpace;
    };

    struct VkBufferCollectionPropertiesFUCHSIA {
        VkStructureType sType;
        void* pNext;
        uint32_t memoryTypeBits;
        uint32_t bufferCount;
        uint32_t createInfoIndex;
        uint64_t sysmemPixelFormat;
        VkFormatFeatureFlags formatFeatures;
        VkSysmemColorSpaceFUCHSIA sysmemColorSpaceIndex;
        VkComponentMapping samplerYcbcrConversionComponents;
        VkSamplerYcbcrModelConversion suggestedYcbcrModel;
        VkSamplerYcbcrRange suggestedYcbcrRange;
        VkChromaLocation suggestedXChromaOffset;
        VkChromaLocation suggestedYChromaOffset;
    };

    struct VkBufferCollectionConstraintsInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        uint32_t minBufferCount;
        uint32_t maxBufferCount;
        uint32_t minBufferCountForCamping;
        uint32_t minBufferCountForDedicatedSlack;
        uint32_t minBufferCountForSharedSlack;
    };

    struct VkBufferConstraintsInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        VkBufferCreateInfo createInfo;
        VkFormatFeatureFlags requiredFormatFeatures;
        VkBufferCollectionConstraintsInfoFUCHSIA bufferCollectionConstraints;
    };

    struct VkImageFormatConstraintsInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        VkImageCreateInfo imageCreateInfo;
        VkFormatFeatureFlags requiredFormatFeatures;
        VkImageFormatConstraintsFlagsFUCHSIA flags;
        uint64_t sysmemPixelFormat;
        uint32_t colorSpaceCount;
        const VkSysmemColorSpaceFUCHSIA* pColorSpaces;
    };

    struct VkImageConstraintsInfoFUCHSIA {
        VkStructureType sType;
        const void* pNext;
        uint32_t formatConstraintsCount;
        const VkImageFormatConstraintsInfoFUCHSIA* pFormatConstraints;
        VkBufferCollectionConstraintsInfoFUCHSIA bufferCollectionConstraints;
        VkImageConstraintsInfoFlagsFUCHSIA flags;
    };

    struct VkCudaModuleCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        size_t dataSize;
        const void* pData;
    };

    struct VkCudaFunctionCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkCudaModuleNV module;
        const char* pName;
    };

    struct VkCudaLaunchInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkCudaFunctionNV function;
        uint32_t gridDimX;
        uint32_t gridDimY;
        uint32_t gridDimZ;
        uint32_t blockDimX;
        uint32_t blockDimY;
        uint32_t blockDimZ;
        uint32_t sharedMemBytes;
        size_t paramCount;
        const void* const * pParams;
        size_t extraCount;
        const void* const * pExtras;
    };

    struct VkPhysicalDeviceRGBA10X6FormatsFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 formatRgba10x6WithoutYCbCrSampler;
    };

    struct VkFormatProperties3 {
        VkStructureType sType;
        void* pNext;
        VkFormatFeatureFlags2 linearTilingFeatures;
        VkFormatFeatureFlags2 optimalTilingFeatures;
        VkFormatFeatureFlags2 bufferFeatures;
    };

    struct VkFormatProperties3KHR {
    };

    struct VkDrmFormatModifierPropertiesList2EXT {
        VkStructureType sType;
        void* pNext;
        uint32_t drmFormatModifierCount;
        VkDrmFormatModifierProperties2EXT* pDrmFormatModifierProperties;
    };

    struct VkDrmFormatModifierProperties2EXT {
        uint64_t drmFormatModifier;
        uint32_t drmFormatModifierPlaneCount;
        VkFormatFeatureFlags2 drmFormatModifierTilingFeatures;
    };

    struct VkAndroidHardwareBufferFormatProperties2ANDROID {
        VkStructureType sType;
        void* pNext;
        VkFormat format;
        uint64_t externalFormat;
        VkFormatFeatureFlags2 formatFeatures;
        VkComponentMapping samplerYcbcrConversionComponents;
        VkSamplerYcbcrModelConversion suggestedYcbcrModel;
        VkSamplerYcbcrRange suggestedYcbcrRange;
        VkChromaLocation suggestedXChromaOffset;
        VkChromaLocation suggestedYChromaOffset;
    };

    struct VkPipelineRenderingCreateInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t viewMask;
        uint32_t colorAttachmentCount;
        const VkFormat* pColorAttachmentFormats;
        VkFormat depthAttachmentFormat;
        VkFormat stencilAttachmentFormat;
    };

    struct VkPipelineRenderingCreateInfoKHR {
    };

    struct VkRenderingInfo {
        VkStructureType sType;
        const void* pNext;
        VkRenderingFlags flags;
        VkRect2D renderArea;
        uint32_t layerCount;
        uint32_t viewMask;
        uint32_t colorAttachmentCount;
        const VkRenderingAttachmentInfo* pColorAttachments;
        const VkRenderingAttachmentInfo* pDepthAttachment;
        const VkRenderingAttachmentInfo* pStencilAttachment;
    };

    struct VkRenderingInfoKHR {
    };

    struct VkRenderingEndInfoKHR {
        VkStructureType sType;
        const void* pNext;
    };

    struct VkRenderingEndInfoEXT {
    };

    struct VkRenderingAttachmentInfo {
        VkStructureType sType;
        const void* pNext;
        VkImageView imageView;
        VkImageLayout imageLayout;
        VkResolveModeFlagBits resolveMode;
        VkImageView resolveImageView;
        VkImageLayout resolveImageLayout;
        VkAttachmentLoadOp loadOp;
        VkAttachmentStoreOp storeOp;
        VkClearValue clearValue;
    };

    struct VkRenderingAttachmentInfoKHR {
    };

    struct VkRenderingFragmentShadingRateAttachmentInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkImageView imageView;
        VkImageLayout imageLayout;
        VkExtent2D shadingRateAttachmentTexelSize;
    };

    struct VkRenderingFragmentDensityMapAttachmentInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkImageView imageView;
        VkImageLayout imageLayout;
    };

    struct VkPhysicalDeviceDynamicRenderingFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 dynamicRendering;
    };

    struct VkPhysicalDeviceDynamicRenderingFeaturesKHR {
    };

    struct VkCommandBufferInheritanceRenderingInfo {
        VkStructureType sType;
        const void* pNext;
        VkRenderingFlags flags;
        uint32_t viewMask;
        uint32_t colorAttachmentCount;
        const VkFormat* pColorAttachmentFormats;
        VkFormat depthAttachmentFormat;
        VkFormat stencilAttachmentFormat;
        VkSampleCountFlagBits rasterizationSamples;
    };

    struct VkCommandBufferInheritanceRenderingInfoKHR {
    };

    struct VkAttachmentSampleCountInfoAMD {
        VkStructureType sType;
        const void* pNext;
        uint32_t colorAttachmentCount;
        const VkSampleCountFlagBits* pColorAttachmentSamples;
        VkSampleCountFlagBits depthStencilAttachmentSamples;
    };

    struct VkAttachmentSampleCountInfoNV {
    };

    struct VkMultiviewPerViewAttributesInfoNVX {
        VkStructureType sType;
        const void* pNext;
        VkBool32 perViewAttributes;
        VkBool32 perViewAttributesPositionXOnly;
    };

    struct VkPhysicalDeviceImageViewMinLodFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 minLod;
    };

    struct VkImageViewMinLodCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        float minLod;
    };

    struct VkPhysicalDeviceRasterizationOrderAttachmentAccessFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 rasterizationOrderColorAttachmentAccess;
        VkBool32 rasterizationOrderDepthAttachmentAccess;
        VkBool32 rasterizationOrderStencilAttachmentAccess;
    };

    struct VkPhysicalDeviceRasterizationOrderAttachmentAccessFeaturesARM {
    };

    struct VkPhysicalDeviceLinearColorAttachmentFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 linearColorAttachment;
    };

    struct VkPhysicalDeviceGraphicsPipelineLibraryFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 graphicsPipelineLibrary;
    };

    struct VkPhysicalDevicePipelineBinaryFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 pipelineBinaries;
    };

    struct VkDevicePipelineBinaryInternalCacheControlKHR {
        VkStructureType sType;
        const void* pNext;
        VkBool32 disableInternalCache;
    };

    struct VkPhysicalDevicePipelineBinaryPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 pipelineBinaryInternalCache;
        VkBool32 pipelineBinaryInternalCacheControl;
        VkBool32 pipelineBinaryPrefersInternalCache;
        VkBool32 pipelineBinaryPrecompiledInternalCache;
        VkBool32 pipelineBinaryCompressedData;
    };

    struct VkPhysicalDeviceGraphicsPipelineLibraryPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 graphicsPipelineLibraryFastLinking;
        VkBool32 graphicsPipelineLibraryIndependentInterpolationDecoration;
    };

    struct VkGraphicsPipelineLibraryCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkGraphicsPipelineLibraryFlagsEXT flags;
    };

    struct VkPhysicalDeviceDescriptorSetHostMappingFeaturesVALVE {
        VkStructureType sType;
        void* pNext;
        VkBool32 descriptorSetHostMapping;
    };

    struct VkDescriptorSetBindingReferenceVALVE {
        VkStructureType sType;
        const void* pNext;
        VkDescriptorSetLayout descriptorSetLayout;
        uint32_t binding;
    };

    struct VkDescriptorSetLayoutHostMappingInfoVALVE {
        VkStructureType sType;
        void* pNext;
        size_t descriptorOffset;
        uint32_t descriptorSize;
    };

    struct VkPhysicalDeviceNestedCommandBufferFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 nestedCommandBuffer;
        VkBool32 nestedCommandBufferRendering;
        VkBool32 nestedCommandBufferSimultaneousUse;
    };

    struct VkPhysicalDeviceNestedCommandBufferPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t maxCommandBufferNestingLevel;
    };

    struct VkPhysicalDeviceShaderModuleIdentifierFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderModuleIdentifier;
    };

    struct VkPhysicalDeviceShaderModuleIdentifierPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint8_t shaderModuleIdentifierAlgorithmUUID[16];
    };

    struct VkPipelineShaderStageModuleIdentifierCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t identifierSize;
        const uint8_t* pIdentifier;
    };

    struct VkShaderModuleIdentifierEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t identifierSize;
        uint8_t identifier[32];
    };

    struct VkImageCompressionControlEXT {
        VkStructureType sType;
        const void* pNext;
        VkImageCompressionFlagsEXT flags;
        uint32_t compressionControlPlaneCount;
        VkImageCompressionFixedRateFlagsEXT* pFixedRateFlags;
    };

    struct VkPhysicalDeviceImageCompressionControlFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 imageCompressionControl;
    };

    struct VkImageCompressionPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkImageCompressionFlagsEXT imageCompressionFlags;
        VkImageCompressionFixedRateFlagsEXT imageCompressionFixedRateFlags;
    };

    struct VkPhysicalDeviceImageCompressionControlSwapchainFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 imageCompressionControlSwapchain;
    };

    struct VkImageSubresource2 {
        VkStructureType sType;
        void* pNext;
        VkImageSubresource imageSubresource;
    };

    struct VkImageSubresource2KHR {
    };

    struct VkImageSubresource2EXT {
    };

    struct VkSubresourceLayout2 {
        VkStructureType sType;
        void* pNext;
        VkSubresourceLayout subresourceLayout;
    };

    struct VkSubresourceLayout2KHR {
    };

    struct VkSubresourceLayout2EXT {
    };

    struct VkRenderPassCreationControlEXT {
        VkStructureType sType;
        const void* pNext;
        VkBool32 disallowMerging;
    };

    struct VkRenderPassCreationFeedbackInfoEXT {
        uint32_t postMergeSubpassCount;
    };

    struct VkRenderPassCreationFeedbackCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkRenderPassCreationFeedbackInfoEXT* pRenderPassFeedback;
    };

    struct VkRenderPassSubpassFeedbackInfoEXT {
        VkSubpassMergeStatusEXT subpassMergeStatus;
        char description[256];
        uint32_t postMergeIndex;
    };

    struct VkRenderPassSubpassFeedbackCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkRenderPassSubpassFeedbackInfoEXT* pSubpassFeedback;
    };

    struct VkPhysicalDeviceSubpassMergeFeedbackFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 subpassMergeFeedback;
    };

    struct VkMicromapBuildInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkMicromapTypeEXT type;
        VkBuildMicromapFlagsEXT flags;
        VkBuildMicromapModeEXT mode;
        VkMicromapEXT dstMicromap;
        uint32_t usageCountsCount;
        const VkMicromapUsageEXT* pUsageCounts;
        const VkMicromapUsageEXT* const* ppUsageCounts;
        VkDeviceOrHostAddressConstKHR data;
        VkDeviceOrHostAddressKHR scratchData;
        VkDeviceOrHostAddressConstKHR triangleArray;
        VkDeviceSize triangleArrayStride;
    };

    struct VkMicromapCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkMicromapCreateFlagsEXT createFlags;
        VkBuffer buffer;
        VkDeviceSize offset;
        VkDeviceSize size;
        VkMicromapTypeEXT type;
        VkDeviceAddress deviceAddress;
    };

    struct VkMicromapVersionInfoEXT {
        VkStructureType sType;
        const void* pNext;
        const uint8_t* pVersionData;
    };

    struct VkCopyMicromapInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkMicromapEXT src;
        VkMicromapEXT dst;
        VkCopyMicromapModeEXT mode;
    };

    struct VkCopyMicromapToMemoryInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkMicromapEXT src;
        VkDeviceOrHostAddressKHR dst;
        VkCopyMicromapModeEXT mode;
    };

    struct VkCopyMemoryToMicromapInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDeviceOrHostAddressConstKHR src;
        VkMicromapEXT dst;
        VkCopyMicromapModeEXT mode;
    };

    struct VkMicromapBuildSizesInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDeviceSize micromapSize;
        VkDeviceSize buildScratchSize;
        VkBool32 discardable;
    };

    struct VkMicromapUsageEXT {
        uint32_t count;
        uint32_t subdivisionLevel;
        uint32_t format;
    };

    struct VkMicromapTriangleEXT {
        uint32_t dataOffset;
        uint16_t subdivisionLevel;
        uint16_t format;
    };

    struct VkPhysicalDeviceOpacityMicromapFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 micromap;
        VkBool32 micromapCaptureReplay;
        VkBool32 micromapHostCommands;
    };

    struct VkPhysicalDeviceOpacityMicromapPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t maxOpacity2StateSubdivisionLevel;
        uint32_t maxOpacity4StateSubdivisionLevel;
    };

    struct VkAccelerationStructureTrianglesOpacityMicromapEXT {
        VkStructureType sType;
        void* pNext;
        VkIndexType indexType;
        VkDeviceOrHostAddressConstKHR indexBuffer;
        VkDeviceSize indexStride;
        uint32_t baseTriangle;
        uint32_t usageCountsCount;
        const VkMicromapUsageEXT* pUsageCounts;
        const VkMicromapUsageEXT* const* ppUsageCounts;
        VkMicromapEXT micromap;
    };

    struct VkPhysicalDeviceDisplacementMicromapFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 displacementMicromap;
    };

    struct VkPhysicalDeviceDisplacementMicromapPropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t maxDisplacementMicromapSubdivisionLevel;
    };

    struct VkAccelerationStructureTrianglesDisplacementMicromapNV {
        VkStructureType sType;
        void* pNext;
        VkFormat displacementBiasAndScaleFormat;
        VkFormat displacementVectorFormat;
        VkDeviceOrHostAddressConstKHR displacementBiasAndScaleBuffer;
        VkDeviceSize displacementBiasAndScaleStride;
        VkDeviceOrHostAddressConstKHR displacementVectorBuffer;
        VkDeviceSize displacementVectorStride;
        VkDeviceOrHostAddressConstKHR displacedMicromapPrimitiveFlags;
        VkDeviceSize displacedMicromapPrimitiveFlagsStride;
        VkIndexType indexType;
        VkDeviceOrHostAddressConstKHR indexBuffer;
        VkDeviceSize indexStride;
        uint32_t baseTriangle;
        uint32_t usageCountsCount;
        const VkMicromapUsageEXT* pUsageCounts;
        const VkMicromapUsageEXT* const* ppUsageCounts;
        VkMicromapEXT micromap;
    };

    struct VkPipelinePropertiesIdentifierEXT {
        VkStructureType sType;
        void* pNext;
        uint8_t pipelineIdentifier[16];
    };

    struct VkPhysicalDevicePipelinePropertiesFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 pipelinePropertiesIdentifier;
    };

    struct VkPhysicalDeviceShaderEarlyAndLateFragmentTestsFeaturesAMD {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderEarlyAndLateFragmentTests;
    };

    struct VkExternalMemoryAcquireUnmodifiedEXT {
        VkStructureType sType;
        const void* pNext;
        VkBool32 acquireUnmodifiedMemory;
    };

    struct VkExportMetalObjectCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkExportMetalObjectTypeFlagBitsEXT exportObjectType;
    };

    struct VkExportMetalObjectsInfoEXT {
        VkStructureType sType;
        const void* pNext;
    };

    struct VkExportMetalDeviceInfoEXT {
        VkStructureType sType;
        const void* pNext;
        MTLDevice_id mtlDevice;
    };

    struct VkExportMetalCommandQueueInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkQueue queue;
        MTLCommandQueue_id mtlCommandQueue;
    };

    struct VkExportMetalBufferInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
        MTLBuffer_id mtlBuffer;
    };

    struct VkImportMetalBufferInfoEXT {
        VkStructureType sType;
        const void* pNext;
        MTLBuffer_id mtlBuffer;
    };

    struct VkExportMetalTextureInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkImage image;
        VkImageView imageView;
        VkBufferView bufferView;
        VkImageAspectFlagBits plane;
        MTLTexture_id mtlTexture;
    };

    struct VkImportMetalTextureInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkImageAspectFlagBits plane;
        MTLTexture_id mtlTexture;
    };

    struct VkExportMetalIOSurfaceInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkImage image;
        IOSurfaceRef ioSurface;
    };

    struct VkImportMetalIOSurfaceInfoEXT {
        VkStructureType sType;
        const void* pNext;
        IOSurfaceRef ioSurface;
    };

    struct VkExportMetalSharedEventInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore semaphore;
        VkEvent event;
        MTLSharedEvent_id mtlSharedEvent;
    };

    struct VkImportMetalSharedEventInfoEXT {
        VkStructureType sType;
        const void* pNext;
        MTLSharedEvent_id mtlSharedEvent;
    };

    struct VkPhysicalDeviceNonSeamlessCubeMapFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 nonSeamlessCubeMap;
    };

    struct VkPhysicalDevicePipelineRobustnessFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 pipelineRobustness;
    };

    struct VkPhysicalDevicePipelineRobustnessFeaturesEXT {
    };

    struct VkPipelineRobustnessCreateInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineRobustnessBufferBehavior storageBuffers;
        VkPipelineRobustnessBufferBehavior uniformBuffers;
        VkPipelineRobustnessBufferBehavior vertexInputs;
        VkPipelineRobustnessImageBehavior images;
    };

    struct VkPipelineRobustnessCreateInfoEXT {
    };

    struct VkPhysicalDevicePipelineRobustnessProperties {
        VkStructureType sType;
        void* pNext;
        VkPipelineRobustnessBufferBehavior defaultRobustnessStorageBuffers;
        VkPipelineRobustnessBufferBehavior defaultRobustnessUniformBuffers;
        VkPipelineRobustnessBufferBehavior defaultRobustnessVertexInputs;
        VkPipelineRobustnessImageBehavior defaultRobustnessImages;
    };

    struct VkPhysicalDevicePipelineRobustnessPropertiesEXT {
    };

    struct VkImageViewSampleWeightCreateInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        VkOffset2D filterCenter;
        VkExtent2D filterSize;
        uint32_t numPhases;
    };

    struct VkPhysicalDeviceImageProcessingFeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 textureSampleWeighted;
        VkBool32 textureBoxFilter;
        VkBool32 textureBlockMatch;
    };

    struct VkPhysicalDeviceImageProcessingPropertiesQCOM {
        VkStructureType sType;
        void* pNext;
        uint32_t maxWeightFilterPhases;
        VkExtent2D maxWeightFilterDimension;
        VkExtent2D maxBlockMatchRegion;
        VkExtent2D maxBoxFilterBlockSize;
    };

    struct VkPhysicalDeviceTilePropertiesFeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 tileProperties;
    };

    struct VkTilePropertiesQCOM {
        VkStructureType sType;
        void* pNext;
        VkExtent3D tileSize;
        VkExtent2D apronSize;
        VkOffset2D origin;
    };

    struct VkTileMemoryBindInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
    };

    struct VkPhysicalDeviceAmigoProfilingFeaturesSEC {
        VkStructureType sType;
        void* pNext;
        VkBool32 amigoProfiling;
    };

    struct VkAmigoProfilingSubmitInfoSEC {
        VkStructureType sType;
        const void* pNext;
        uint64_t firstDrawTimestamp;
        uint64_t swapBufferTimestamp;
    };

    struct VkPhysicalDeviceAttachmentFeedbackLoopLayoutFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 attachmentFeedbackLoopLayout;
    };

    struct VkPhysicalDeviceDepthClampZeroOneFeaturesEXT {
    };

    struct VkAttachmentFeedbackLoopInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkBool32 feedbackLoopEnable;
    };

    struct VkPhysicalDeviceAddressBindingReportFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 reportAddressBinding;
    };

    struct VkRenderingAttachmentFlagsInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkRenderingAttachmentFlagsKHR flags;
    };

    struct VkResolveImageModeInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkResolveImageFlagsKHR flags;
        VkResolveModeFlagBits resolveMode;
        VkResolveModeFlagBits stencilResolveMode;
    };

    struct VkDeviceAddressBindingCallbackDataEXT {
        VkStructureType sType;
        void* pNext;
        VkDeviceAddressBindingFlagsEXT flags;
        VkDeviceAddress baseAddress;
        VkDeviceSize size;
        VkDeviceAddressBindingTypeEXT bindingType;
    };

    struct VkPhysicalDeviceOpticalFlowFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 opticalFlow;
    };

    struct VkPhysicalDeviceOpticalFlowPropertiesNV {
        VkStructureType sType;
        void* pNext;
        VkOpticalFlowGridSizeFlagsNV supportedOutputGridSizes;
        VkOpticalFlowGridSizeFlagsNV supportedHintGridSizes;
        VkBool32 hintSupported;
        VkBool32 costSupported;
        VkBool32 bidirectionalFlowSupported;
        VkBool32 globalFlowSupported;
        uint32_t minWidth;
        uint32_t minHeight;
        uint32_t maxWidth;
        uint32_t maxHeight;
        uint32_t maxNumRegionsOfInterest;
    };

    struct VkOpticalFlowImageFormatInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkOpticalFlowUsageFlagsNV usage;
    };

    struct VkOpticalFlowImageFormatPropertiesNV {
        VkStructureType sType;
        void* pNext;
        VkFormat format;
    };

    struct VkOpticalFlowSessionCreateInfoNV {
        VkStructureType sType;
        void* pNext;
        uint32_t width;
        uint32_t height;
        VkFormat imageFormat;
        VkFormat flowVectorFormat;
        VkFormat costFormat;
        VkOpticalFlowGridSizeFlagsNV outputGridSize;
        VkOpticalFlowGridSizeFlagsNV hintGridSize;
        VkOpticalFlowPerformanceLevelNV performanceLevel;
        VkOpticalFlowSessionCreateFlagsNV flags;
    };

    struct VkOpticalFlowSessionCreatePrivateDataInfoNV {
        VkStructureType sType;
        void* pNext;
        uint32_t id;
        uint32_t size;
        const void* pPrivateData;
    };

    struct VkOpticalFlowExecuteInfoNV {
        VkStructureType sType;
        void* pNext;
        VkOpticalFlowExecuteFlagsNV flags;
        uint32_t regionCount;
        const VkRect2D* pRegions;
    };

    struct VkPhysicalDeviceFaultFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 deviceFault;
        VkBool32 deviceFaultVendorBinary;
    };

    struct VkDeviceFaultAddressInfoEXT {
        VkDeviceFaultAddressTypeEXT addressType;
        VkDeviceAddress reportedAddress;
        VkDeviceSize addressPrecision;
    };

    struct VkDeviceFaultVendorInfoEXT {
        char description[256];
        uint64_t vendorFaultCode;
        uint64_t vendorFaultData;
    };

    struct VkDeviceFaultCountsEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t addressInfoCount;
        uint32_t vendorInfoCount;
        VkDeviceSize vendorBinarySize;
    };

    struct VkDeviceFaultInfoEXT {
        VkStructureType sType;
        void* pNext;
        char description[256];
        VkDeviceFaultAddressInfoEXT* pAddressInfos;
        VkDeviceFaultVendorInfoEXT* pVendorInfos;
        void* pVendorBinaryData;
    };

    struct VkDeviceFaultVendorBinaryHeaderVersionOneEXT {
        uint32_t headerSize;
        VkDeviceFaultVendorBinaryHeaderVersionEXT headerVersion;
        uint32_t vendorID;
        uint32_t deviceID;
        uint32_t driverVersion;
        uint8_t pipelineCacheUUID[16];
        uint32_t applicationNameOffset;
        uint32_t applicationVersion;
        uint32_t engineNameOffset;
        uint32_t engineVersion;
        uint32_t apiVersion;
    };

    struct VkPhysicalDevicePipelineLibraryGroupHandlesFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 pipelineLibraryGroupHandles;
    };

    struct VkDepthBiasInfoEXT {
        VkStructureType sType;
        const void* pNext;
        float depthBiasConstantFactor;
        float depthBiasClamp;
        float depthBiasSlopeFactor;
    };

    struct VkDepthBiasRepresentationInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDepthBiasRepresentationEXT depthBiasRepresentation;
        VkBool32 depthBiasExact;
    };

    struct VkDecompressMemoryRegionNV {
        VkDeviceAddress srcAddress;
        VkDeviceAddress dstAddress;
        VkDeviceSize compressedSize;
        VkDeviceSize decompressedSize;
        VkMemoryDecompressionMethodFlagsNV decompressionMethod;
    };

    struct VkDecompressMemoryRegionEXT {
        VkDeviceAddress srcAddress;
        VkDeviceAddress dstAddress;
        VkDeviceSize compressedSize;
        VkDeviceSize decompressedSize;
    };

    struct VkDecompressMemoryInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkMemoryDecompressionMethodFlagsEXT decompressionMethod;
        uint32_t regionCount;
        const VkDecompressMemoryRegionEXT* pRegions;
    };

    struct VkPhysicalDeviceShaderCoreBuiltinsPropertiesARM {
        VkStructureType sType;
        void* pNext;
        uint64_t shaderCoreMask;
        uint32_t shaderCoreCount;
        uint32_t shaderWarpsPerCore;
    };

    struct VkPhysicalDeviceShaderCoreBuiltinsFeaturesARM {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderCoreBuiltins;
    };

    struct VkFrameBoundaryEXT {
        VkStructureType sType;
        const void* pNext;
        VkFrameBoundaryFlagsEXT flags;
        uint64_t frameID;
        uint32_t imageCount;
        const VkImage* pImages;
        uint32_t bufferCount;
        const VkBuffer* pBuffers;
        uint64_t tagName;
        size_t tagSize;
        const void* pTag;
    };

    struct VkPhysicalDeviceFrameBoundaryFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 frameBoundary;
    };

    struct VkPhysicalDeviceDynamicRenderingUnusedAttachmentsFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 dynamicRenderingUnusedAttachments;
    };

    struct VkPhysicalDeviceInternallySynchronizedQueuesFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 internallySynchronizedQueues;
    };

    struct VkSurfacePresentModeKHR {
        VkStructureType sType;
        void* pNext;
        VkPresentModeKHR presentMode;
    };

    struct VkSurfacePresentModeEXT {
    };

    struct VkSurfacePresentScalingCapabilitiesKHR {
        VkStructureType sType;
        void* pNext;
        VkPresentScalingFlagsKHR supportedPresentScaling;
        VkPresentGravityFlagsKHR supportedPresentGravityX;
        VkPresentGravityFlagsKHR supportedPresentGravityY;
        VkExtent2D minScaledImageExtent;
        VkExtent2D maxScaledImageExtent;
    };

    struct VkSurfacePresentScalingCapabilitiesEXT {
    };

    struct VkSurfacePresentModeCompatibilityKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t presentModeCount;
        VkPresentModeKHR* pPresentModes;
    };

    struct VkSurfacePresentModeCompatibilityEXT {
    };

    struct VkPhysicalDeviceSwapchainMaintenance1FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 swapchainMaintenance1;
    };

    struct VkPhysicalDeviceSwapchainMaintenance1FeaturesEXT {
    };

    struct VkSwapchainPresentFenceInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t swapchainCount;
        const VkFence* pFences;
    };

    struct VkSwapchainPresentFenceInfoEXT {
    };

    struct VkSwapchainPresentModesCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t presentModeCount;
        const VkPresentModeKHR* pPresentModes;
    };

    struct VkSwapchainPresentModesCreateInfoEXT {
    };

    struct VkSwapchainPresentModeInfoKHR {
        VkStructureType sType;
        const void* pNext;
        uint32_t swapchainCount;
        const VkPresentModeKHR* pPresentModes;
    };

    struct VkSwapchainPresentModeInfoEXT {
    };

    struct VkSwapchainPresentScalingCreateInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkPresentScalingFlagsKHR scalingBehavior;
        VkPresentGravityFlagsKHR presentGravityX;
        VkPresentGravityFlagsKHR presentGravityY;
    };

    struct VkSwapchainPresentScalingCreateInfoEXT {
    };

    struct VkReleaseSwapchainImagesInfoKHR {
        VkStructureType sType;
        const void* pNext;
        VkSwapchainKHR swapchain;
        uint32_t imageIndexCount;
        const uint32_t* pImageIndices;
    };

    struct VkReleaseSwapchainImagesInfoEXT {
    };

    struct VkPhysicalDeviceDepthBiasControlFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 depthBiasControl;
        VkBool32 leastRepresentableValueForceUnormRepresentation;
        VkBool32 floatRepresentation;
        VkBool32 depthBiasExact;
    };

    struct VkPhysicalDeviceRayTracingInvocationReorderFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 rayTracingInvocationReorder;
    };

    struct VkPhysicalDeviceRayTracingInvocationReorderFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 rayTracingInvocationReorder;
    };

    struct VkPhysicalDeviceRayTracingInvocationReorderPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkRayTracingInvocationReorderModeEXT rayTracingInvocationReorderReorderingHint;
        uint32_t maxShaderBindingTableRecordIndex;
    };

    struct VkPhysicalDeviceRayTracingInvocationReorderPropertiesNV {
        VkStructureType sType;
        void* pNext;
        VkRayTracingInvocationReorderModeEXT rayTracingInvocationReorderReorderingHint;
    };

    struct VkPhysicalDeviceExtendedSparseAddressSpaceFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 extendedSparseAddressSpace;
    };

    struct VkPhysicalDeviceExtendedSparseAddressSpacePropertiesNV {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize extendedSparseAddressSpaceSize;
        VkImageUsageFlags extendedSparseImageUsageFlags;
        VkBufferUsageFlags extendedSparseBufferUsageFlags;
    };

    struct VkDirectDriverLoadingInfoLUNARG {
        VkStructureType sType;
        void* pNext;
        VkDirectDriverLoadingFlagsLUNARG flags;
        PFN_vkGetInstanceProcAddrLUNARG pfnGetInstanceProcAddr;
    };

    struct VkDirectDriverLoadingListLUNARG {
        VkStructureType sType;
        const void* pNext;
        VkDirectDriverLoadingModeLUNARG mode;
        uint32_t driverCount;
        const VkDirectDriverLoadingInfoLUNARG* pDrivers;
    };

    struct VkPhysicalDeviceMultiviewPerViewViewportsFeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 multiviewPerViewViewports;
    };

    struct VkPhysicalDeviceRayTracingPositionFetchFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 rayTracingPositionFetch;
    };

    struct VkDeviceImageSubresourceInfo {
        VkStructureType sType;
        const void* pNext;
        const VkImageCreateInfo* pCreateInfo;
        const VkImageSubresource2* pSubresource;
    };

    struct VkDeviceImageSubresourceInfoKHR {
    };

    struct VkPhysicalDeviceShaderCorePropertiesARM {
        VkStructureType sType;
        void* pNext;
        uint32_t pixelRate;
        uint32_t texelRate;
        uint32_t fmaRate;
    };

    struct VkPhysicalDeviceMultiviewPerViewRenderAreasFeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 multiviewPerViewRenderAreas;
    };

    struct VkMultiviewPerViewRenderAreasRenderPassBeginInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        uint32_t perViewRenderAreaCount;
        const VkRect2D* pPerViewRenderAreas;
    };

    struct VkQueryLowLatencySupportNV {
        VkStructureType sType;
        const void* pNext;
        void* pQueriedLowLatencyData;
    };

    struct VkMemoryMapInfo {
        VkStructureType sType;
        const void* pNext;
        VkMemoryMapFlags flags;
        VkDeviceMemory memory;
        VkDeviceSize offset;
        VkDeviceSize size;
    };

    struct VkMemoryMapInfoKHR {
    };

    struct VkMemoryUnmapInfo {
        VkStructureType sType;
        const void* pNext;
        VkMemoryUnmapFlags flags;
        VkDeviceMemory memory;
    };

    struct VkMemoryUnmapInfoKHR {
    };

    struct VkPhysicalDeviceShaderObjectFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderObject;
    };

    struct VkPhysicalDeviceShaderObjectPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint8_t shaderBinaryUUID[16];
        uint32_t shaderBinaryVersion;
    };

    struct VkShaderCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkShaderCreateFlagsEXT flags;
        VkShaderStageFlagBits stage;
        VkShaderStageFlags nextStage;
        VkShaderCodeTypeEXT codeType;
        size_t codeSize;
        const void* pCode;
        const char* pName;
        uint32_t setLayoutCount;
        const VkDescriptorSetLayout* pSetLayouts;
        uint32_t pushConstantRangeCount;
        const VkPushConstantRange* pPushConstantRanges;
        const VkSpecializationInfo* pSpecializationInfo;
    };

    struct VkPhysicalDeviceShaderTileImageFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderTileImageColorReadAccess;
        VkBool32 shaderTileImageDepthReadAccess;
        VkBool32 shaderTileImageStencilReadAccess;
    };

    struct VkPhysicalDeviceShaderTileImagePropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderTileImageCoherentReadAccelerated;
        VkBool32 shaderTileImageReadSampleFromPixelRateInvocation;
        VkBool32 shaderTileImageReadFromHelperInvocation;
    };

    struct VkImportScreenBufferInfoQNX {
        VkStructureType sType;
        const void* pNext;
        struct _screen_buffer* buffer;
    };

    struct VkScreenBufferPropertiesQNX {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize allocationSize;
        uint32_t memoryTypeBits;
    };

    struct VkScreenBufferFormatPropertiesQNX {
        VkStructureType sType;
        void* pNext;
        VkFormat format;
        uint64_t externalFormat;
        uint64_t screenUsage;
        VkFormatFeatureFlags formatFeatures;
        VkComponentMapping samplerYcbcrConversionComponents;
        VkSamplerYcbcrModelConversion suggestedYcbcrModel;
        VkSamplerYcbcrRange suggestedYcbcrRange;
        VkChromaLocation suggestedXChromaOffset;
        VkChromaLocation suggestedYChromaOffset;
    };

    struct VkExternalFormatQNX {
        VkStructureType sType;
        void* pNext;
        uint64_t externalFormat;
    };

    struct VkPhysicalDeviceExternalMemoryScreenBufferFeaturesQNX {
        VkStructureType sType;
        void* pNext;
        VkBool32 screenBufferImport;
    };

    struct VkPhysicalDeviceCooperativeMatrixFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 cooperativeMatrix;
        VkBool32 cooperativeMatrixRobustBufferAccess;
    };

    struct VkCooperativeMatrixPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        uint32_t MSize;
        uint32_t NSize;
        uint32_t KSize;
        VkComponentTypeKHR AType;
        VkComponentTypeKHR BType;
        VkComponentTypeKHR CType;
        VkComponentTypeKHR ResultType;
        VkBool32 saturatingAccumulation;
        VkScopeKHR scope;
    };

    struct VkPhysicalDeviceCooperativeMatrixPropertiesKHR {
        VkStructureType sType;
        void* pNext;
        VkShaderStageFlags cooperativeMatrixSupportedStages;
    };

    struct VkPhysicalDeviceCooperativeMatrixConversionFeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 cooperativeMatrixConversion;
    };

    struct VkPhysicalDeviceShaderEnqueuePropertiesAMDX {
        VkStructureType sType;
        void* pNext;
        uint32_t maxExecutionGraphDepth;
        uint32_t maxExecutionGraphShaderOutputNodes;
        uint32_t maxExecutionGraphShaderPayloadSize;
        uint32_t maxExecutionGraphShaderPayloadCount;
        uint32_t executionGraphDispatchAddressAlignment;
        uint32_t maxExecutionGraphWorkgroupCount[3];
        uint32_t maxExecutionGraphWorkgroups;
    };

    struct VkPhysicalDeviceShaderEnqueueFeaturesAMDX {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderEnqueue;
        VkBool32 shaderMeshEnqueue;
    };

    struct VkExecutionGraphPipelineCreateInfoAMDX {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCreateFlags flags;
        uint32_t stageCount;
        const VkPipelineShaderStageCreateInfo* pStages;
        const VkPipelineLibraryCreateInfoKHR* pLibraryInfo;
        VkPipelineLayout layout;
        VkPipeline basePipelineHandle;
        int32_t basePipelineIndex;
    };

    struct VkPipelineShaderStageNodeCreateInfoAMDX {
        VkStructureType sType;
        const void* pNext;
        const char* pName;
        uint32_t index;
    };

    struct VkExecutionGraphPipelineScratchSizeAMDX {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize minSize;
        VkDeviceSize maxSize;
        VkDeviceSize sizeGranularity;
    };

    struct VkDispatchGraphInfoAMDX {
        uint32_t nodeIndex;
        uint32_t payloadCount;
        VkDeviceOrHostAddressConstAMDX payloads;
        uint64_t payloadStride;
    };

    struct VkDispatchGraphCountInfoAMDX {
        uint32_t count;
        VkDeviceOrHostAddressConstAMDX infos;
        uint64_t stride;
    };

    struct VkPhysicalDeviceAntiLagFeaturesAMD {
        VkStructureType sType;
        void* pNext;
        VkBool32 antiLag;
    };

    struct VkAntiLagDataAMD {
        VkStructureType sType;
        const void* pNext;
        VkAntiLagModeAMD mode;
        uint32_t maxFPS;
        const VkAntiLagPresentationInfoAMD* pPresentationInfo;
    };

    struct VkAntiLagPresentationInfoAMD {
        VkStructureType sType;
        void* pNext;
        VkAntiLagStageAMD stage;
        uint64_t frameIndex;
    };

    struct VkBindMemoryStatus {
        VkStructureType sType;
        const void* pNext;
        VkResult* pResult;
    };

    struct VkPhysicalDeviceTileMemoryHeapFeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 tileMemoryHeap;
    };

    struct VkPhysicalDeviceTileMemoryHeapPropertiesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 queueSubmitBoundary;
        VkBool32 tileBufferTransfers;
    };

    struct VkTileMemorySizeInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        VkDeviceSize size;
    };

    struct VkTileMemoryRequirementsQCOM {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize size;
        VkDeviceSize alignment;
    };

    struct VkBindMemoryStatusKHR {
    };

    struct VkBindDescriptorSetsInfo {
        VkStructureType sType;
        const void* pNext;
        VkShaderStageFlags stageFlags;
        VkPipelineLayout layout;
        uint32_t firstSet;
        uint32_t descriptorSetCount;
        const VkDescriptorSet* pDescriptorSets;
        uint32_t dynamicOffsetCount;
        const uint32_t* pDynamicOffsets;
    };

    struct VkBindDescriptorSetsInfoKHR {
    };

    struct VkPushConstantsInfo {
        VkStructureType sType;
        const void* pNext;
        VkPipelineLayout layout;
        VkShaderStageFlags stageFlags;
        uint32_t offset;
        uint32_t size;
        const void* pValues;
    };

    struct VkPushConstantsInfoKHR {
    };

    struct VkPushDescriptorSetInfo {
        VkStructureType sType;
        const void* pNext;
        VkShaderStageFlags stageFlags;
        VkPipelineLayout layout;
        uint32_t set;
        uint32_t descriptorWriteCount;
        const VkWriteDescriptorSet* pDescriptorWrites;
    };

    struct VkPushDescriptorSetInfoKHR {
    };

    struct VkPushDescriptorSetWithTemplateInfo {
        VkStructureType sType;
        const void* pNext;
        VkDescriptorUpdateTemplate descriptorUpdateTemplate;
        VkPipelineLayout layout;
        uint32_t set;
        const void* pData;
    };

    struct VkPushDescriptorSetWithTemplateInfoKHR {
    };

    struct VkSetDescriptorBufferOffsetsInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkShaderStageFlags stageFlags;
        VkPipelineLayout layout;
        uint32_t firstSet;
        uint32_t setCount;
        const uint32_t* pBufferIndices;
        const VkDeviceSize* pOffsets;
    };

    struct VkBindDescriptorBufferEmbeddedSamplersInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkShaderStageFlags stageFlags;
        VkPipelineLayout layout;
        uint32_t set;
    };

    struct VkPhysicalDeviceCubicClampFeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 cubicRangeClamp;
    };

    struct VkPhysicalDeviceYcbcrDegammaFeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 ycbcrDegamma;
    };

    struct VkSamplerYcbcrConversionYcbcrDegammaCreateInfoQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 enableYDegamma;
        VkBool32 enableCbCrDegamma;
    };

    struct VkPhysicalDeviceCubicWeightsFeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 selectableCubicWeights;
    };

    struct VkSamplerCubicWeightsCreateInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        VkCubicFilterWeightsQCOM cubicWeights;
    };

    struct VkBlitImageCubicWeightsInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        VkCubicFilterWeightsQCOM cubicWeights;
    };

    struct VkPhysicalDeviceImageProcessing2FeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 textureBlockMatch2;
    };

    struct VkPhysicalDeviceImageProcessing2PropertiesQCOM {
        VkStructureType sType;
        void* pNext;
        VkExtent2D maxBlockMatchWindow;
    };

    struct VkSamplerBlockMatchWindowCreateInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        VkExtent2D windowExtent;
        VkBlockMatchWindowCompareModeQCOM windowCompareMode;
    };

    struct VkPhysicalDeviceDescriptorPoolOverallocationFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 descriptorPoolOverallocation;
    };

    struct VkPhysicalDeviceLayeredDriverPropertiesMSFT {
        VkStructureType sType;
        void* pNext;
        VkLayeredDriverUnderlyingApiMSFT underlyingAPI;
    };

    struct VkPhysicalDevicePerStageDescriptorSetFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 perStageDescriptorSet;
        VkBool32 dynamicPipelineLayout;
    };

    struct VkPhysicalDeviceExternalFormatResolveFeaturesANDROID {
        VkStructureType sType;
        void* pNext;
        VkBool32 externalFormatResolve;
    };

    struct VkPhysicalDeviceExternalFormatResolvePropertiesANDROID {
        VkStructureType sType;
        void* pNext;
        VkBool32 nullColorAttachmentWithExternalFormatResolve;
        VkChromaLocation externalFormatResolveChromaOffsetX;
        VkChromaLocation externalFormatResolveChromaOffsetY;
    };

    struct VkAndroidHardwareBufferFormatResolvePropertiesANDROID {
        VkStructureType sType;
        void* pNext;
        VkFormat colorAttachmentFormat;
    };

    struct VkLatencySleepModeInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkBool32 lowLatencyMode;
        VkBool32 lowLatencyBoost;
        uint32_t minimumIntervalUs;
    };

    struct VkLatencySleepInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkSemaphore signalSemaphore;
        uint64_t value;
    };

    struct VkSetLatencyMarkerInfoNV {
        VkStructureType sType;
        const void* pNext;
        uint64_t presentID;
        VkLatencyMarkerNV marker;
    };

    struct VkGetLatencyMarkerInfoNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t timingCount;
        VkLatencyTimingsFrameReportNV* pTimings;
    };

    struct VkLatencyTimingsFrameReportNV {
        VkStructureType sType;
        void* pNext;
        uint64_t presentID;
        uint64_t inputSampleTimeUs;
        uint64_t simStartTimeUs;
        uint64_t simEndTimeUs;
        uint64_t renderSubmitStartTimeUs;
        uint64_t renderSubmitEndTimeUs;
        uint64_t presentStartTimeUs;
        uint64_t presentEndTimeUs;
        uint64_t driverStartTimeUs;
        uint64_t driverEndTimeUs;
        uint64_t osRenderQueueStartTimeUs;
        uint64_t osRenderQueueEndTimeUs;
        uint64_t gpuRenderStartTimeUs;
        uint64_t gpuRenderEndTimeUs;
    };

    struct VkOutOfBandQueueTypeInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkOutOfBandQueueTypeNV queueType;
    };

    struct VkLatencySubmissionPresentIdNV {
        VkStructureType sType;
        const void* pNext;
        uint64_t presentID;
    };

    struct VkSwapchainLatencyCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkBool32 latencyModeEnable;
    };

    struct VkLatencySurfaceCapabilitiesNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t presentModeCount;
        VkPresentModeKHR* pPresentModes;
    };

    struct VkPhysicalDeviceCudaKernelLaunchFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 cudaKernelLaunchFeatures;
    };

    struct VkPhysicalDeviceCudaKernelLaunchPropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t computeCapabilityMinor;
        uint32_t computeCapabilityMajor;
    };

    struct VkDeviceQueueShaderCoreControlCreateInfoARM {
        VkStructureType sType;
        void* pNext;
        uint32_t shaderCoreCount;
    };

    struct VkPhysicalDeviceSchedulingControlsFeaturesARM {
        VkStructureType sType;
        void* pNext;
        VkBool32 schedulingControls;
    };

    struct VkPhysicalDeviceSchedulingControlsPropertiesARM {
        VkStructureType sType;
        void* pNext;
        VkPhysicalDeviceSchedulingControlsFlagsARM schedulingControlsFlags;
    };

    struct VkPhysicalDeviceRelaxedLineRasterizationFeaturesIMG {
        VkStructureType sType;
        void* pNext;
        VkBool32 relaxedLineRasterization;
    };

    struct VkPhysicalDeviceRenderPassStripedFeaturesARM {
        VkStructureType sType;
        void* pNext;
        VkBool32 renderPassStriped;
    };

    struct VkPhysicalDeviceRenderPassStripedPropertiesARM {
        VkStructureType sType;
        void* pNext;
        VkExtent2D renderPassStripeGranularity;
        uint32_t maxRenderPassStripes;
    };

    struct VkRenderPassStripeInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkRect2D stripeArea;
    };

    struct VkRenderPassStripeBeginInfoARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t stripeInfoCount;
        const VkRenderPassStripeInfoARM* pStripeInfos;
    };

    struct VkRenderPassStripeSubmitInfoARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t stripeSemaphoreInfoCount;
        const VkSemaphoreSubmitInfo* pStripeSemaphoreInfos;
    };

    struct VkPhysicalDevicePipelineOpacityMicromapFeaturesARM {
        VkStructureType sType;
        void* pNext;
        VkBool32 pipelineOpacityMicromap;
    };

    struct VkPhysicalDeviceShaderMaximalReconvergenceFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderMaximalReconvergence;
    };

    struct VkPhysicalDeviceShaderSubgroupRotateFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderSubgroupRotate;
        VkBool32 shaderSubgroupRotateClustered;
    };

    struct VkPhysicalDeviceShaderSubgroupRotateFeaturesKHR {
    };

    struct VkPhysicalDeviceShaderExpectAssumeFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderExpectAssume;
    };

    struct VkPhysicalDeviceShaderExpectAssumeFeaturesKHR {
    };

    struct VkPhysicalDeviceShaderFloatControls2Features {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderFloatControls2;
    };

    struct VkPhysicalDeviceShaderFloatControls2FeaturesKHR {
    };

    struct VkPhysicalDeviceDynamicRenderingLocalReadFeatures {
        VkStructureType sType;
        void* pNext;
        VkBool32 dynamicRenderingLocalRead;
    };

    struct VkPhysicalDeviceDynamicRenderingLocalReadFeaturesKHR {
    };

    struct VkRenderingAttachmentLocationInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t colorAttachmentCount;
        const uint32_t* pColorAttachmentLocations;
    };

    struct VkRenderingAttachmentLocationInfoKHR {
    };

    struct VkRenderingInputAttachmentIndexInfo {
        VkStructureType sType;
        const void* pNext;
        uint32_t colorAttachmentCount;
        const uint32_t* pColorAttachmentInputIndices;
        const uint32_t* pDepthInputAttachmentIndex;
        const uint32_t* pStencilInputAttachmentIndex;
    };

    struct VkRenderingInputAttachmentIndexInfoKHR {
    };

    struct VkPhysicalDeviceShaderQuadControlFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderQuadControl;
    };

    struct VkPhysicalDeviceShaderAtomicFloat16VectorFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderFloat16VectorAtomics;
    };

    struct VkPhysicalDeviceMapMemoryPlacedFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 memoryMapPlaced;
        VkBool32 memoryMapRangePlaced;
        VkBool32 memoryUnmapReserve;
    };

    struct VkPhysicalDeviceMapMemoryPlacedPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize minPlacedMemoryMapAlignment;
    };

    struct VkMemoryMapPlacedInfoEXT {
        VkStructureType sType;
        const void* pNext;
        void* pPlacedAddress;
    };

    struct VkPhysicalDeviceShaderBfloat16FeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderBFloat16Type;
        VkBool32 shaderBFloat16DotProduct;
        VkBool32 shaderBFloat16CooperativeMatrix;
    };

    struct VkPhysicalDeviceRawAccessChainsFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderRawAccessChains;
    };

    struct VkPhysicalDeviceCommandBufferInheritanceFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 commandBufferInheritance;
    };

    struct VkPhysicalDeviceImageAlignmentControlFeaturesMESA {
        VkStructureType sType;
        void* pNext;
        VkBool32 imageAlignmentControl;
    };

    struct VkPhysicalDeviceImageAlignmentControlPropertiesMESA {
        VkStructureType sType;
        void* pNext;
        uint32_t supportedImageAlignmentMask;
    };

    struct VkImageAlignmentControlCreateInfoMESA {
        VkStructureType sType;
        const void* pNext;
        uint32_t maximumRequestedAlignment;
    };

    struct VkPhysicalDeviceShaderReplicatedCompositesFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderReplicatedComposites;
    };

    struct VkPhysicalDevicePresentModeFifoLatestReadyFeaturesEXT {
    };

    struct VkPhysicalDevicePresentModeFifoLatestReadyFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentModeFifoLatestReady;
    };

    struct VkDepthClampRangeEXT {
        float minDepthClamp;
        float maxDepthClamp;
    };

    struct VkPhysicalDeviceCooperativeMatrix2FeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 cooperativeMatrixWorkgroupScope;
        VkBool32 cooperativeMatrixFlexibleDimensions;
        VkBool32 cooperativeMatrixReductions;
        VkBool32 cooperativeMatrixConversions;
        VkBool32 cooperativeMatrixPerElementOperations;
        VkBool32 cooperativeMatrixTensorAddressing;
        VkBool32 cooperativeMatrixBlockLoads;
    };

    struct VkPhysicalDeviceCooperativeMatrix2PropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t cooperativeMatrixWorkgroupScopeMaxWorkgroupSize;
        uint32_t cooperativeMatrixFlexibleDimensionsMaxDimension;
        uint32_t cooperativeMatrixWorkgroupScopeReservedSharedMemory;
    };

    struct VkCooperativeMatrixFlexibleDimensionsPropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t MGranularity;
        uint32_t NGranularity;
        uint32_t KGranularity;
        VkComponentTypeKHR AType;
        VkComponentTypeKHR BType;
        VkComponentTypeKHR CType;
        VkComponentTypeKHR ResultType;
        VkBool32 saturatingAccumulation;
        VkScopeKHR scope;
        uint32_t workgroupInvocations;
    };

    struct VkPhysicalDeviceHdrVividFeaturesHUAWEI {
        VkStructureType sType;
        void* pNext;
        VkBool32 hdrVivid;
    };

    struct VkPhysicalDeviceVertexAttributeRobustnessFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 vertexAttributeRobustness;
    };

    struct VkPhysicalDeviceDenseGeometryFormatFeaturesAMDX {
        VkStructureType sType;
        void* pNext;
        VkBool32 denseGeometryFormat;
    };

    struct VkAccelerationStructureDenseGeometryFormatTrianglesDataAMDX {
        VkStructureType sType;
        const void* pNext;
        VkDeviceOrHostAddressConstKHR compressedData;
        VkDeviceSize dataSize;
        uint32_t numTriangles;
        uint32_t numVertices;
        uint32_t maxPrimitiveIndex;
        uint32_t maxGeometryIndex;
        VkCompressedTriangleFormatAMDX format;
    };

    struct VkPhysicalDeviceDepthClampZeroOneFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 depthClampZeroOne;
    };

    struct VkPhysicalDeviceCooperativeVectorFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 cooperativeVector;
        VkBool32 cooperativeVectorTraining;
    };

    struct VkCooperativeVectorPropertiesNV {
        VkStructureType sType;
        void* pNext;
        VkComponentTypeKHR inputType;
        VkComponentTypeKHR inputInterpretation;
        VkComponentTypeKHR matrixInterpretation;
        VkComponentTypeKHR biasInterpretation;
        VkComponentTypeKHR resultType;
        VkBool32 transpose;
    };

    struct VkPhysicalDeviceCooperativeVectorPropertiesNV {
        VkStructureType sType;
        void* pNext;
        VkShaderStageFlags cooperativeVectorSupportedStages;
        VkBool32 cooperativeVectorTrainingFloat16Accumulation;
        VkBool32 cooperativeVectorTrainingFloat32Accumulation;
        uint32_t maxCooperativeVectorComponents;
    };

    struct VkConvertCooperativeVectorMatrixInfoNV {
        VkStructureType sType;
        const void* pNext;
        size_t srcSize;
        VkDeviceOrHostAddressConstKHR srcData;
        size_t* pDstSize;
        VkDeviceOrHostAddressKHR dstData;
        VkComponentTypeKHR srcComponentType;
        VkComponentTypeKHR dstComponentType;
        uint32_t numRows;
        uint32_t numColumns;
        VkCooperativeVectorMatrixLayoutNV srcLayout;
        size_t srcStride;
        VkCooperativeVectorMatrixLayoutNV dstLayout;
        size_t dstStride;
    };

    struct VkPhysicalDeviceTileShadingFeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 tileShading;
        VkBool32 tileShadingFragmentStage;
        VkBool32 tileShadingColorAttachments;
        VkBool32 tileShadingDepthAttachments;
        VkBool32 tileShadingStencilAttachments;
        VkBool32 tileShadingInputAttachments;
        VkBool32 tileShadingSampledAttachments;
        VkBool32 tileShadingPerTileDraw;
        VkBool32 tileShadingPerTileDispatch;
        VkBool32 tileShadingDispatchTile;
        VkBool32 tileShadingApron;
        VkBool32 tileShadingAnisotropicApron;
        VkBool32 tileShadingAtomicOps;
        VkBool32 tileShadingImageProcessing;
    };

    struct VkPhysicalDeviceTileShadingPropertiesQCOM {
        VkStructureType sType;
        void* pNext;
        uint32_t maxApronSize;
        VkBool32 preferNonCoherent;
        VkExtent2D tileGranularity;
        VkExtent2D maxTileShadingRate;
    };

    struct VkRenderPassTileShadingCreateInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        VkTileShadingRenderPassFlagsQCOM flags;
        VkExtent2D tileApronSize;
    };

    struct VkPerTileBeginInfoQCOM {
        VkStructureType sType;
        const void* pNext;
    };

    struct VkPerTileEndInfoQCOM {
        VkStructureType sType;
        const void* pNext;
    };

    struct VkDispatchTileInfoQCOM {
        VkStructureType sType;
        const void* pNext;
    };

    struct VkPhysicalDeviceFragmentDensityMapLayeredPropertiesVALVE {
        VkStructureType sType;
        void* pNext;
        uint32_t maxFragmentDensityMapLayers;
    };

    struct VkPhysicalDeviceFragmentDensityMapLayeredFeaturesVALVE {
        VkStructureType sType;
        void* pNext;
        VkBool32 fragmentDensityMapLayered;
    };

    struct VkPipelineFragmentDensityMapLayeredCreateInfoVALVE {
        VkStructureType sType;
        const void* pNext;
        uint32_t maxFragmentDensityMapLayers;
    };

    struct VkSetPresentConfigNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t numFramesPerBatch;
        uint32_t presentConfigFeedback;
    };

    struct VkPhysicalDevicePresentMeteringFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 presentMetering;
    };

    struct VkExternalComputeQueueDeviceCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t reservedExternalQueues;
    };

    struct VkExternalComputeQueueCreateInfoNV {
        VkStructureType sType;
        const void* pNext;
        VkQueue preferredQueue;
    };

    struct VkExternalComputeQueueDataParamsNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t deviceIndex;
    };

    struct VkPhysicalDeviceExternalComputeQueuePropertiesNV {
        VkStructureType sType;
        void* pNext;
        uint32_t externalDataSize;
        uint32_t maxExternalQueues;
    };

    struct VkPhysicalDeviceShaderUniformBufferUnsizedArrayFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderUniformBufferUnsizedArray;
    };

    struct VkPhysicalDeviceFormatPackFeaturesARM {
        VkStructureType sType;
        void* pNext;
        VkBool32 formatPack;
    };

    struct VkTensorDescriptionARM {
        VkStructureType sType;
        const void* pNext;
        VkTensorTilingARM tiling;
        VkFormat format;
        uint32_t dimensionCount;
        const int64_t* pDimensions;
        const int64_t* pStrides;
        VkTensorUsageFlagsARM usage;
    };

    struct VkTensorCreateInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkTensorCreateFlagsARM flags;
        const VkTensorDescriptionARM* pDescription;
        VkSharingMode sharingMode;
        uint32_t queueFamilyIndexCount;
        const uint32_t* pQueueFamilyIndices;
    };

    struct VkTensorViewCreateInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkTensorViewCreateFlagsARM flags;
        VkTensorARM tensor;
        VkFormat format;
    };

    struct VkTensorMemoryRequirementsInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkTensorARM tensor;
    };

    struct VkBindTensorMemoryInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkTensorARM tensor;
        VkDeviceMemory memory;
        VkDeviceSize memoryOffset;
    };

    struct VkWriteDescriptorSetTensorARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t tensorViewCount;
        const VkTensorViewARM* pTensorViews;
    };

    struct VkTensorFormatPropertiesARM {
        VkStructureType sType;
        void* pNext;
        VkFormatFeatureFlags2 optimalTilingTensorFeatures;
        VkFormatFeatureFlags2 linearTilingTensorFeatures;
    };

    struct VkPhysicalDeviceTensorPropertiesARM {
        VkStructureType sType;
        void* pNext;
        uint32_t maxTensorDimensionCount;
        uint64_t maxTensorElements;
        uint64_t maxPerDimensionTensorElements;
        int64_t maxTensorStride;
        uint64_t maxTensorSize;
        uint32_t maxTensorShaderAccessArrayLength;
        uint32_t maxTensorShaderAccessSize;
        uint32_t maxDescriptorSetStorageTensors;
        uint32_t maxPerStageDescriptorSetStorageTensors;
        uint32_t maxDescriptorSetUpdateAfterBindStorageTensors;
        uint32_t maxPerStageDescriptorUpdateAfterBindStorageTensors;
        VkBool32 shaderStorageTensorArrayNonUniformIndexingNative;
        VkShaderStageFlags shaderTensorSupportedStages;
    };

    struct VkTensorMemoryBarrierARM {
        VkStructureType sType;
        const void* pNext;
        VkPipelineStageFlags2 srcStageMask;
        VkAccessFlags2 srcAccessMask;
        VkPipelineStageFlags2 dstStageMask;
        VkAccessFlags2 dstAccessMask;
        uint32_t srcQueueFamilyIndex;
        uint32_t dstQueueFamilyIndex;
        VkTensorARM tensor;
    };

    struct VkTensorDependencyInfoARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t tensorMemoryBarrierCount;
        const VkTensorMemoryBarrierARM* pTensorMemoryBarriers;
    };

    struct VkPhysicalDeviceTensorFeaturesARM {
        VkStructureType sType;
        void* pNext;
        VkBool32 tensorNonPacked;
        VkBool32 shaderTensorAccess;
        VkBool32 shaderStorageTensorArrayDynamicIndexing;
        VkBool32 shaderStorageTensorArrayNonUniformIndexing;
        VkBool32 descriptorBindingStorageTensorUpdateAfterBind;
        VkBool32 tensors;
    };

    struct VkDeviceTensorMemoryRequirementsARM {
        VkStructureType sType;
        const void* pNext;
        const VkTensorCreateInfoARM* pCreateInfo;
    };

    struct VkCopyTensorInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkTensorARM srcTensor;
        VkTensorARM dstTensor;
        uint32_t regionCount;
        const VkTensorCopyARM* pRegions;
    };

    struct VkTensorCopyARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t dimensionCount;
        const uint64_t* pSrcOffset;
        const uint64_t* pDstOffset;
        const uint64_t* pExtent;
    };

    struct VkMemoryDedicatedAllocateInfoTensorARM {
        VkStructureType sType;
        const void* pNext;
        VkTensorARM tensor;
    };

    struct VkPhysicalDeviceDescriptorBufferTensorPropertiesARM {
        VkStructureType sType;
        void* pNext;
        size_t tensorCaptureReplayDescriptorDataSize;
        size_t tensorViewCaptureReplayDescriptorDataSize;
        size_t tensorDescriptorSize;
    };

    struct VkPhysicalDeviceDescriptorBufferTensorFeaturesARM {
        VkStructureType sType;
        void* pNext;
        VkBool32 descriptorBufferTensorDescriptors;
    };

    struct VkTensorCaptureDescriptorDataInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkTensorARM tensor;
    };

    struct VkTensorViewCaptureDescriptorDataInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkTensorViewARM tensorView;
    };

    struct VkDescriptorGetTensorInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkTensorViewARM tensorView;
    };

    struct VkFrameBoundaryTensorsARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t tensorCount;
        const VkTensorARM* pTensors;
    };

    struct VkPhysicalDeviceExternalTensorInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkTensorCreateFlagsARM flags;
        const VkTensorDescriptionARM* pDescription;
        VkExternalMemoryHandleTypeFlagBits handleType;
    };

    struct VkExternalTensorPropertiesARM {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryProperties externalMemoryProperties;
    };

    struct VkExternalMemoryTensorCreateInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkExternalMemoryHandleTypeFlags handleTypes;
    };

    struct VkPhysicalDeviceShaderFloat8FeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderFloat8;
        VkBool32 shaderFloat8CooperativeMatrix;
    };

    struct VkSurfaceCreateInfoOHOS {
        VkStructureType sType;
        const void* pNext;
        VkSurfaceCreateFlagsOHOS flags;
        OHNativeWindow* window;
    };

    struct VkPhysicalDeviceDataGraphFeaturesARM {
        VkStructureType sType;
        void* pNext;
        VkBool32 dataGraph;
        VkBool32 dataGraphUpdateAfterBind;
        VkBool32 dataGraphSpecializationConstants;
        VkBool32 dataGraphDescriptorBuffer;
        VkBool32 dataGraphShaderModule;
    };

    struct VkDataGraphPipelineConstantTensorSemiStructuredSparsityInfoARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t dimension;
        uint32_t zeroCount;
        uint32_t groupSize;
    };

    struct VkDataGraphPipelineConstantARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t id;
        const void* pConstantData;
    };

    struct VkDataGraphPipelineResourceInfoARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t descriptorSet;
        uint32_t binding;
        uint32_t arrayElement;
    };

    struct VkDataGraphPipelineCompilerControlCreateInfoARM {
        VkStructureType sType;
        const void* pNext;
        const char* pVendorOptions;
    };

    struct VkDataGraphPipelineCreateInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkPipelineCreateFlags2KHR flags;
        VkPipelineLayout layout;
        uint32_t resourceInfoCount;
        const VkDataGraphPipelineResourceInfoARM* pResourceInfos;
    };

    struct VkDataGraphPipelineShaderModuleCreateInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkShaderModule module;
        const char* pName;
        const VkSpecializationInfo* pSpecializationInfo;
        uint32_t constantCount;
        const VkDataGraphPipelineConstantARM* pConstants;
    };

    struct VkDataGraphPipelineSessionCreateInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkDataGraphPipelineSessionCreateFlagsARM flags;
        VkPipeline dataGraphPipeline;
    };

    struct VkDataGraphPipelineSessionBindPointRequirementsInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkDataGraphPipelineSessionARM session;
    };

    struct VkDataGraphPipelineSessionBindPointRequirementARM {
        VkStructureType sType;
        void* pNext;
        VkDataGraphPipelineSessionBindPointARM bindPoint;
        VkDataGraphPipelineSessionBindPointTypeARM bindPointType;
        uint32_t numObjects;
    };

    struct VkDataGraphPipelineSessionMemoryRequirementsInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkDataGraphPipelineSessionARM session;
        VkDataGraphPipelineSessionBindPointARM bindPoint;
        uint32_t objectIndex;
    };

    struct VkBindDataGraphPipelineSessionMemoryInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkDataGraphPipelineSessionARM session;
        VkDataGraphPipelineSessionBindPointARM bindPoint;
        uint32_t objectIndex;
        VkDeviceMemory memory;
        VkDeviceSize memoryOffset;
    };

    struct VkDataGraphPipelineInfoARM {
        VkStructureType sType;
        const void* pNext;
        VkPipeline dataGraphPipeline;
    };

    struct VkDataGraphPipelinePropertyQueryResultARM {
        VkStructureType sType;
        void* pNext;
        VkDataGraphPipelinePropertyARM property;
        VkBool32 isText;
        size_t dataSize;
        void* pData;
    };

    struct VkDataGraphPipelineIdentifierCreateInfoARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t identifierSize;
        const uint8_t* pIdentifier;
    };

    struct VkDataGraphPipelineDispatchInfoARM {
        VkStructureType sType;
        void* pNext;
        VkDataGraphPipelineDispatchFlagsARM flags;
    };

    struct VkPhysicalDeviceDataGraphProcessingEngineARM {
        VkPhysicalDeviceDataGraphProcessingEngineTypeARM type;
        VkBool32 isForeign;
    };

    struct VkPhysicalDeviceDataGraphOperationSupportARM {
        VkPhysicalDeviceDataGraphOperationTypeARM operationType;
        char name[128];
        uint32_t version;
    };

    struct VkQueueFamilyDataGraphPropertiesARM {
        VkStructureType sType;
        void* pNext;
        VkPhysicalDeviceDataGraphProcessingEngineARM engine;
        VkPhysicalDeviceDataGraphOperationSupportARM operation;
    };

    struct VkPhysicalDeviceQueueFamilyDataGraphProcessingEngineInfoARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t queueFamilyIndex;
        VkPhysicalDeviceDataGraphProcessingEngineTypeARM engineType;
    };

    struct VkQueueFamilyDataGraphProcessingEnginePropertiesARM {
        VkStructureType sType;
        void* pNext;
        VkExternalSemaphoreHandleTypeFlags foreignSemaphoreHandleTypes;
        VkExternalMemoryHandleTypeFlags foreignMemoryHandleTypes;
    };

    struct VkDataGraphProcessingEngineCreateInfoARM {
        VkStructureType sType;
        const void* pNext;
        uint32_t processingEngineCount;
        VkPhysicalDeviceDataGraphProcessingEngineARM* pProcessingEngines;
    };

    struct VkPhysicalDevicePipelineCacheIncrementalModeFeaturesSEC {
        VkStructureType sType;
        void* pNext;
        VkBool32 pipelineCacheIncrementalMode;
    };

    struct VkDataGraphPipelineBuiltinModelCreateInfoQCOM {
        VkStructureType sType;
        const void* pNext;
        const VkPhysicalDeviceDataGraphOperationSupportARM* pOperation;
    };

    struct VkPhysicalDeviceDataGraphModelFeaturesQCOM {
        VkStructureType sType;
        void* pNext;
        VkBool32 dataGraphModel;
    };

    struct VkPhysicalDeviceShaderUntypedPointersFeaturesKHR {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderUntypedPointers;
    };

    struct VkNativeBufferOHOS {
        VkStructureType sType;
        const void* pNext;
        struct OHBufferHandle* handle;
    };

    struct VkSwapchainImageCreateInfoOHOS {
        VkStructureType sType;
        const void* pNext;
        VkSwapchainImageUsageFlagsOHOS usage;
    };

    struct VkPhysicalDevicePresentationPropertiesOHOS {
        VkStructureType sType;
        void* pNext;
        VkBool32 sharedImage;
    };

    struct VkPhysicalDeviceVideoEncodeRgbConversionFeaturesVALVE {
        VkStructureType sType;
        void* pNext;
        VkBool32 videoEncodeRgbConversion;
    };

    struct VkVideoEncodeRgbConversionCapabilitiesVALVE {
        VkStructureType sType;
        void* pNext;
        VkVideoEncodeRgbModelConversionFlagsVALVE rgbModels;
        VkVideoEncodeRgbRangeCompressionFlagsVALVE rgbRanges;
        VkVideoEncodeRgbChromaOffsetFlagsVALVE xChromaOffsets;
        VkVideoEncodeRgbChromaOffsetFlagsVALVE yChromaOffsets;
    };

    struct VkVideoEncodeProfileRgbConversionInfoVALVE {
        VkStructureType sType;
        const void* pNext;
        VkBool32 performEncodeRgbConversion;
    };

    struct VkVideoEncodeSessionRgbConversionCreateInfoVALVE {
        VkStructureType sType;
        const void* pNext;
        VkVideoEncodeRgbModelConversionFlagBitsVALVE rgbModel;
        VkVideoEncodeRgbRangeCompressionFlagBitsVALVE rgbRange;
        VkVideoEncodeRgbChromaOffsetFlagBitsVALVE xChromaOffset;
        VkVideoEncodeRgbChromaOffsetFlagBitsVALVE yChromaOffset;
    };

    struct VkPhysicalDeviceShader64BitIndexingFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shader64BitIndexing;
    };

    struct VkNativeBufferUsageOHOS {
        VkStructureType sType;
        void* pNext;
        uint64_t OHOSNativeBufferUsage;
    };

    struct VkNativeBufferPropertiesOHOS {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize allocationSize;
        uint32_t memoryTypeBits;
    };

    struct VkNativeBufferFormatPropertiesOHOS {
        VkStructureType sType;
        void* pNext;
        VkFormat format;
        uint64_t externalFormat;
        VkFormatFeatureFlags formatFeatures;
        VkComponentMapping samplerYcbcrConversionComponents;
        VkSamplerYcbcrModelConversion suggestedYcbcrModel;
        VkSamplerYcbcrRange suggestedYcbcrRange;
        VkChromaLocation suggestedXChromaOffset;
        VkChromaLocation suggestedYChromaOffset;
    };

    struct VkImportNativeBufferInfoOHOS {
        VkStructureType sType;
        const void* pNext;
        struct OH_NativeBuffer* buffer;
    };

    struct VkMemoryGetNativeBufferInfoOHOS {
        VkStructureType sType;
        const void* pNext;
        VkDeviceMemory memory;
    };

    struct VkExternalFormatOHOS {
        VkStructureType sType;
        void* pNext;
        uint64_t externalFormat;
    };

    struct VkPhysicalDevicePerformanceCountersByRegionFeaturesARM {
        VkStructureType sType;
        void* pNext;
        VkBool32 performanceCountersByRegion;
    };

    struct VkPhysicalDevicePerformanceCountersByRegionPropertiesARM {
        VkStructureType sType;
        void* pNext;
        uint32_t maxPerRegionPerformanceCounters;
        VkExtent2D performanceCounterRegionSize;
        uint32_t rowStrideAlignment;
        uint32_t regionAlignment;
        VkBool32 identityTransformOrder;
    };

    struct VkPerformanceCounterARM {
        VkStructureType sType;
        void* pNext;
        uint32_t counterID;
    };

    struct VkPerformanceCounterDescriptionARM {
        VkStructureType sType;
        void* pNext;
        VkPerformanceCounterDescriptionFlagsARM flags;
        char name[256];
    };

    struct VkRenderPassPerformanceCountersByRegionBeginInfoARM {
        VkStructureType sType;
        void* pNext;
        uint32_t counterAddressCount;
        const VkDeviceAddress* pCounterAddresses;
        VkBool32 serializeRegions;
        uint32_t counterIndexCount;
        uint32_t* pCounterIndices;
    };

    struct VkComputeOccupancyPriorityParametersNV {
        VkStructureType sType;
        const void* pNext;
        float occupancyPriority;
        float occupancyThrottling;
    };

    struct VkPhysicalDeviceComputeOccupancyPriorityFeaturesNV {
        VkStructureType sType;
        void* pNext;
        VkBool32 computeOccupancyPriority;
    };

    struct VkPhysicalDeviceShaderLongVectorFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 longVector;
    };

    struct VkPhysicalDeviceShaderLongVectorPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        uint32_t maxVectorComponents;
    };

    struct VkPhysicalDeviceTextureCompressionASTC3DFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 textureCompressionASTC_3D;
    };

    struct VkPhysicalDeviceShaderSubgroupPartitionedFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 shaderSubgroupPartitioned;
    };

    struct VkHostAddressRangeEXT {
        void* address;
        size_t size;
    };

    struct VkHostAddressRangeConstEXT {
        const void* address;
        size_t size;
    };

    struct VkDeviceAddressRangeEXT {
        VkDeviceAddress address;
        VkDeviceSize size;
    };

    struct VkTexelBufferDescriptorInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkFormat format;
        VkDeviceAddressRangeEXT addressRange;
    };

    struct VkImageDescriptorInfoEXT {
        VkStructureType sType;
        const void* pNext;
        const VkImageViewCreateInfo* pView;
        VkImageLayout layout;
    };

    union VkResourceDescriptorDataEXT {
        const VkImageDescriptorInfoEXT* pImage;
        const VkTexelBufferDescriptorInfoEXT* pTexelBuffer;
        const VkDeviceAddressRangeEXT* pAddressRange;
        const VkTensorViewCreateInfoARM* pTensorARM;
    };

    struct VkResourceDescriptorInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDescriptorType type;
        VkResourceDescriptorDataEXT data;
    };

    struct VkBindHeapInfoEXT {
        VkStructureType sType;
        const void* pNext;
        VkDeviceAddressRangeEXT heapRange;
        VkDeviceSize reservedRangeOffset;
        VkDeviceSize reservedRangeSize;
    };

    struct VkPushDataInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t offset;
        VkHostAddressRangeConstEXT data;
    };

    struct VkDescriptorMappingSourceConstantOffsetEXT {
        uint32_t heapOffset;
        uint32_t heapArrayStride;
        const VkSamplerCreateInfo* pEmbeddedSampler;
        uint32_t samplerHeapOffset;
        uint32_t samplerHeapArrayStride;
    };

    struct VkDescriptorMappingSourcePushIndexEXT {
        uint32_t heapOffset;
        uint32_t pushOffset;
        uint32_t heapIndexStride;
        uint32_t heapArrayStride;
        const VkSamplerCreateInfo* pEmbeddedSampler;
        VkBool32 useCombinedImageSamplerIndex;
        uint32_t samplerHeapOffset;
        uint32_t samplerPushOffset;
        uint32_t samplerHeapIndexStride;
        uint32_t samplerHeapArrayStride;
    };

    struct VkDescriptorMappingSourceIndirectIndexEXT {
        uint32_t heapOffset;
        uint32_t pushOffset;
        uint32_t addressOffset;
        uint32_t heapIndexStride;
        uint32_t heapArrayStride;
        const VkSamplerCreateInfo* pEmbeddedSampler;
        VkBool32 useCombinedImageSamplerIndex;
        uint32_t samplerHeapOffset;
        uint32_t samplerPushOffset;
        uint32_t samplerAddressOffset;
        uint32_t samplerHeapIndexStride;
        uint32_t samplerHeapArrayStride;
    };

    struct VkDescriptorMappingSourceIndirectIndexArrayEXT {
        uint32_t heapOffset;
        uint32_t pushOffset;
        uint32_t addressOffset;
        uint32_t heapIndexStride;
        const VkSamplerCreateInfo* pEmbeddedSampler;
        VkBool32 useCombinedImageSamplerIndex;
        uint32_t samplerHeapOffset;
        uint32_t samplerPushOffset;
        uint32_t samplerAddressOffset;
        uint32_t samplerHeapIndexStride;
    };

    struct VkDescriptorMappingSourceHeapDataEXT {
        uint32_t heapOffset;
        uint32_t pushOffset;
    };

    struct VkDescriptorMappingSourceShaderRecordIndexEXT {
        uint32_t heapOffset;
        uint32_t shaderRecordOffset;
        uint32_t heapIndexStride;
        uint32_t heapArrayStride;
        const VkSamplerCreateInfo* pEmbeddedSampler;
        VkBool32 useCombinedImageSamplerIndex;
        uint32_t samplerHeapOffset;
        uint32_t samplerShaderRecordOffset;
        uint32_t samplerHeapIndexStride;
        uint32_t samplerHeapArrayStride;
    };

    struct VkDescriptorMappingSourceIndirectAddressEXT {
        uint32_t pushOffset;
        uint32_t addressOffset;
    };

    union VkDescriptorMappingSourceDataEXT {
        VkDescriptorMappingSourceConstantOffsetEXT constantOffset;
        VkDescriptorMappingSourcePushIndexEXT pushIndex;
        VkDescriptorMappingSourceIndirectIndexEXT indirectIndex;
        VkDescriptorMappingSourceIndirectIndexArrayEXT indirectIndexArray;
        VkDescriptorMappingSourceHeapDataEXT heapData;
        uint32_t pushDataOffset;
        uint32_t pushAddressOffset;
        VkDescriptorMappingSourceIndirectAddressEXT indirectAddress;
        VkDescriptorMappingSourceShaderRecordIndexEXT shaderRecordIndex;
        uint32_t shaderRecordDataOffset;
        uint32_t shaderRecordAddressOffset;
    };

    struct VkDescriptorSetAndBindingMappingEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t descriptorSet;
        uint32_t firstBinding;
        uint32_t bindingCount;
        VkSpirvResourceTypeFlagsEXT resourceMask;
        VkDescriptorMappingSourceEXT source;
        VkDescriptorMappingSourceDataEXT sourceData;
    };

    struct VkShaderDescriptorSetAndBindingMappingInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t mappingCount;
        const VkDescriptorSetAndBindingMappingEXT* pMappings;
    };

    struct VkSamplerCustomBorderColorIndexCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t index;
    };

    struct VkOpaqueCaptureDataCreateInfoEXT {
        VkStructureType sType;
        const void* pNext;
        const VkHostAddressRangeConstEXT* pData;
    };

    struct VkIndirectCommandsLayoutPushDataTokenNV {
        VkStructureType sType;
        const void* pNext;
        uint32_t pushDataOffset;
        uint32_t pushDataSize;
    };

    struct VkSubsampledImageFormatPropertiesEXT {
        VkStructureType sType;
        const void* pNext;
        uint32_t subsampledImageDescriptorCount;
    };

    struct VkPhysicalDeviceDescriptorHeapFeaturesEXT {
        VkStructureType sType;
        void* pNext;
        VkBool32 descriptorHeap;
        VkBool32 descriptorHeapCaptureReplay;
    };

    struct VkPhysicalDeviceDescriptorHeapPropertiesEXT {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize samplerHeapAlignment;
        VkDeviceSize resourceHeapAlignment;
        VkDeviceSize maxSamplerHeapSize;
        VkDeviceSize maxResourceHeapSize;
        VkDeviceSize minSamplerHeapReservedRange;
        VkDeviceSize minSamplerHeapReservedRangeWithEmbedded;
        VkDeviceSize minResourceHeapReservedRange;
        VkDeviceSize samplerDescriptorSize;
        VkDeviceSize imageDescriptorSize;
        VkDeviceSize bufferDescriptorSize;
        VkDeviceSize samplerDescriptorAlignment;
        VkDeviceSize imageDescriptorAlignment;
        VkDeviceSize bufferDescriptorAlignment;
        VkDeviceSize maxPushDataSize;
        size_t imageCaptureReplayOpaqueDataSize;
        uint32_t maxDescriptorHeapEmbeddedSamplers;
        uint32_t samplerYcbcrConversionCount;
        VkBool32 sparseDescriptorHeaps;
        VkBool32 protectedDescriptorHeaps;
    };

    struct VkCommandBufferInheritanceDescriptorHeapInfoEXT {
        VkStructureType sType;
        const void* pNext;
        const VkBindHeapInfoEXT* pSamplerHeapBindInfo;
        const VkBindHeapInfoEXT* pResourceHeapBindInfo;
    };

    struct VkPhysicalDeviceDescriptorHeapTensorPropertiesARM {
        VkStructureType sType;
        void* pNext;
        VkDeviceSize tensorDescriptorSize;
        VkDeviceSize tensorDescriptorAlignment;
        size_t tensorCaptureReplayOpaqueDataSize;
    };

    VkResult vkCreateInstance(VkInstanceCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkInstance* pInstance);
    void vkDestroyInstance(VkInstance instance, VkAllocationCallbacks* pAllocator);
    VkResult vkEnumeratePhysicalDevices(VkInstance instance, uint32_t* pPhysicalDeviceCount, VkPhysicalDevice* pPhysicalDevices);
    PFN_vkVoidFunction vkGetDeviceProcAddr(VkDevice device, char* pName);
    PFN_vkVoidFunction vkGetInstanceProcAddr(VkInstance instance, char* pName);
    void vkGetPhysicalDeviceProperties(VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties* pProperties);
    void vkGetPhysicalDeviceQueueFamilyProperties(VkPhysicalDevice physicalDevice, uint32_t* pQueueFamilyPropertyCount, VkQueueFamilyProperties* pQueueFamilyProperties);
    void vkGetPhysicalDeviceMemoryProperties(VkPhysicalDevice physicalDevice, VkPhysicalDeviceMemoryProperties* pMemoryProperties);
    void vkGetPhysicalDeviceFeatures(VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures* pFeatures);
    void vkGetPhysicalDeviceFormatProperties(VkPhysicalDevice physicalDevice, VkFormat format, VkFormatProperties* pFormatProperties);
    VkResult vkGetPhysicalDeviceImageFormatProperties(VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkImageTiling tiling, VkImageUsageFlags usage, VkImageCreateFlags flags, VkImageFormatProperties* pImageFormatProperties);
    VkResult vkCreateDevice(VkPhysicalDevice physicalDevice, VkDeviceCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDevice* pDevice);
    void vkDestroyDevice(VkDevice device, VkAllocationCallbacks* pAllocator);
    VkResult vkEnumerateInstanceVersion(uint32_t* pApiVersion);
    VkResult vkEnumerateInstanceLayerProperties(uint32_t* pPropertyCount, VkLayerProperties* pProperties);
    VkResult vkEnumerateInstanceExtensionProperties(char* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties);
    VkResult vkEnumerateDeviceLayerProperties(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkLayerProperties* pProperties);
    VkResult vkEnumerateDeviceExtensionProperties(VkPhysicalDevice physicalDevice, char* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties);
    void vkGetDeviceQueue(VkDevice device, uint32_t queueFamilyIndex, uint32_t queueIndex, VkQueue* pQueue);
    VkResult vkQueueSubmit(VkQueue queue, uint32_t submitCount, VkSubmitInfo* pSubmits, VkFence fence);
    VkResult vkQueueWaitIdle(VkQueue queue);
    VkResult vkDeviceWaitIdle(VkDevice device);
    VkResult vkAllocateMemory(VkDevice device, VkMemoryAllocateInfo* pAllocateInfo, VkAllocationCallbacks* pAllocator, VkDeviceMemory* pMemory);
    void vkFreeMemory(VkDevice device, VkDeviceMemory memory, VkAllocationCallbacks* pAllocator);
    VkResult vkMapMemory(VkDevice device, VkDeviceMemory memory, VkDeviceSize offset, VkDeviceSize size, VkMemoryMapFlags flags, void** ppData);
    void vkUnmapMemory(VkDevice device, VkDeviceMemory memory);
    VkResult vkFlushMappedMemoryRanges(VkDevice device, uint32_t memoryRangeCount, VkMappedMemoryRange* pMemoryRanges);
    VkResult vkInvalidateMappedMemoryRanges(VkDevice device, uint32_t memoryRangeCount, VkMappedMemoryRange* pMemoryRanges);
    void vkGetDeviceMemoryCommitment(VkDevice device, VkDeviceMemory memory, VkDeviceSize* pCommittedMemoryInBytes);
    void vkGetBufferMemoryRequirements(VkDevice device, VkBuffer buffer, VkMemoryRequirements* pMemoryRequirements);
    VkResult vkBindBufferMemory(VkDevice device, VkBuffer buffer, VkDeviceMemory memory, VkDeviceSize memoryOffset);
    void vkGetImageMemoryRequirements(VkDevice device, VkImage image, VkMemoryRequirements* pMemoryRequirements);
    VkResult vkBindImageMemory(VkDevice device, VkImage image, VkDeviceMemory memory, VkDeviceSize memoryOffset);
    void vkGetImageSparseMemoryRequirements(VkDevice device, VkImage image, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements* pSparseMemoryRequirements);
    void vkGetPhysicalDeviceSparseImageFormatProperties(VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkSampleCountFlagBits samples, VkImageUsageFlags usage, VkImageTiling tiling, uint32_t* pPropertyCount, VkSparseImageFormatProperties* pProperties);
    VkResult vkQueueBindSparse(VkQueue queue, uint32_t bindInfoCount, VkBindSparseInfo* pBindInfo, VkFence fence);
    VkResult vkCreateFence(VkDevice device, VkFenceCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkFence* pFence);
    void vkDestroyFence(VkDevice device, VkFence fence, VkAllocationCallbacks* pAllocator);
    VkResult vkResetFences(VkDevice device, uint32_t fenceCount, VkFence* pFences);
    VkResult vkGetFenceStatus(VkDevice device, VkFence fence);
    VkResult vkWaitForFences(VkDevice device, uint32_t fenceCount, VkFence* pFences, VkBool32 waitAll, uint64_t timeout);
    VkResult vkCreateSemaphore(VkDevice device, VkSemaphoreCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSemaphore* pSemaphore);
    void vkDestroySemaphore(VkDevice device, VkSemaphore semaphore, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateEvent(VkDevice device, VkEventCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkEvent* pEvent);
    void vkDestroyEvent(VkDevice device, VkEvent event, VkAllocationCallbacks* pAllocator);
    VkResult vkGetEventStatus(VkDevice device, VkEvent event);
    VkResult vkSetEvent(VkDevice device, VkEvent event);
    VkResult vkResetEvent(VkDevice device, VkEvent event);
    VkResult vkCreateQueryPool(VkDevice device, VkQueryPoolCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkQueryPool* pQueryPool);
    void vkDestroyQueryPool(VkDevice device, VkQueryPool queryPool, VkAllocationCallbacks* pAllocator);
    VkResult vkGetQueryPoolResults(VkDevice device, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, size_t dataSize, void* pData, VkDeviceSize stride, VkQueryResultFlags flags);
    void vkResetQueryPool(VkDevice device, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount);
    VkResult vkCreateBuffer(VkDevice device, VkBufferCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkBuffer* pBuffer);
    void vkDestroyBuffer(VkDevice device, VkBuffer buffer, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateBufferView(VkDevice device, VkBufferViewCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkBufferView* pView);
    void vkDestroyBufferView(VkDevice device, VkBufferView bufferView, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateImage(VkDevice device, VkImageCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkImage* pImage);
    void vkDestroyImage(VkDevice device, VkImage image, VkAllocationCallbacks* pAllocator);
    void vkGetImageSubresourceLayout(VkDevice device, VkImage image, VkImageSubresource* pSubresource, VkSubresourceLayout* pLayout);
    VkResult vkCreateImageView(VkDevice device, VkImageViewCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkImageView* pView);
    void vkDestroyImageView(VkDevice device, VkImageView imageView, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateShaderModule(VkDevice device, VkShaderModuleCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkShaderModule* pShaderModule);
    void vkDestroyShaderModule(VkDevice device, VkShaderModule shaderModule, VkAllocationCallbacks* pAllocator);
    VkResult vkCreatePipelineCache(VkDevice device, VkPipelineCacheCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPipelineCache* pPipelineCache);
    void vkDestroyPipelineCache(VkDevice device, VkPipelineCache pipelineCache, VkAllocationCallbacks* pAllocator);
    VkResult vkGetPipelineCacheData(VkDevice device, VkPipelineCache pipelineCache, size_t* pDataSize, void* pData);
    VkResult vkMergePipelineCaches(VkDevice device, VkPipelineCache dstCache, uint32_t srcCacheCount, VkPipelineCache* pSrcCaches);
    VkResult vkCreatePipelineBinariesKHR(VkDevice device, VkPipelineBinaryCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPipelineBinaryHandlesInfoKHR* pBinaries);
    void vkDestroyPipelineBinaryKHR(VkDevice device, VkPipelineBinaryKHR pipelineBinary, VkAllocationCallbacks* pAllocator);
    VkResult vkGetPipelineKeyKHR(VkDevice device, VkPipelineCreateInfoKHR* pPipelineCreateInfo, VkPipelineBinaryKeyKHR* pPipelineKey);
    VkResult vkGetPipelineBinaryDataKHR(VkDevice device, VkPipelineBinaryDataInfoKHR* pInfo, VkPipelineBinaryKeyKHR* pPipelineBinaryKey, size_t* pPipelineBinaryDataSize, void* pPipelineBinaryData);
    VkResult vkReleaseCapturedPipelineDataKHR(VkDevice device, VkReleaseCapturedPipelineDataInfoKHR* pInfo, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateGraphicsPipelines(VkDevice device, VkPipelineCache pipelineCache, uint32_t createInfoCount, VkGraphicsPipelineCreateInfo* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
    VkResult vkCreateComputePipelines(VkDevice device, VkPipelineCache pipelineCache, uint32_t createInfoCount, VkComputePipelineCreateInfo* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
    VkResult vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI(VkDevice device, VkRenderPass renderpass, VkExtent2D* pMaxWorkgroupSize);
    void vkDestroyPipeline(VkDevice device, VkPipeline pipeline, VkAllocationCallbacks* pAllocator);
    VkResult vkCreatePipelineLayout(VkDevice device, VkPipelineLayoutCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPipelineLayout* pPipelineLayout);
    void vkDestroyPipelineLayout(VkDevice device, VkPipelineLayout pipelineLayout, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateSampler(VkDevice device, VkSamplerCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSampler* pSampler);
    void vkDestroySampler(VkDevice device, VkSampler sampler, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateDescriptorSetLayout(VkDevice device, VkDescriptorSetLayoutCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDescriptorSetLayout* pSetLayout);
    void vkDestroyDescriptorSetLayout(VkDevice device, VkDescriptorSetLayout descriptorSetLayout, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateDescriptorPool(VkDevice device, VkDescriptorPoolCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDescriptorPool* pDescriptorPool);
    void vkDestroyDescriptorPool(VkDevice device, VkDescriptorPool descriptorPool, VkAllocationCallbacks* pAllocator);
    VkResult vkResetDescriptorPool(VkDevice device, VkDescriptorPool descriptorPool, VkDescriptorPoolResetFlags flags);
    VkResult vkAllocateDescriptorSets(VkDevice device, VkDescriptorSetAllocateInfo* pAllocateInfo, VkDescriptorSet* pDescriptorSets);
    VkResult vkFreeDescriptorSets(VkDevice device, VkDescriptorPool descriptorPool, uint32_t descriptorSetCount, VkDescriptorSet* pDescriptorSets);
    void vkUpdateDescriptorSets(VkDevice device, uint32_t descriptorWriteCount, VkWriteDescriptorSet* pDescriptorWrites, uint32_t descriptorCopyCount, VkCopyDescriptorSet* pDescriptorCopies);
    VkResult vkCreateFramebuffer(VkDevice device, VkFramebufferCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkFramebuffer* pFramebuffer);
    void vkDestroyFramebuffer(VkDevice device, VkFramebuffer framebuffer, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateRenderPass(VkDevice device, VkRenderPassCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkRenderPass* pRenderPass);
    void vkDestroyRenderPass(VkDevice device, VkRenderPass renderPass, VkAllocationCallbacks* pAllocator);
    void vkGetRenderAreaGranularity(VkDevice device, VkRenderPass renderPass, VkExtent2D* pGranularity);
    void vkGetRenderingAreaGranularity(VkDevice device, VkRenderingAreaInfo* pRenderingAreaInfo, VkExtent2D* pGranularity);
    VkResult vkCreateCommandPool(VkDevice device, VkCommandPoolCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCommandPool* pCommandPool);
    void vkDestroyCommandPool(VkDevice device, VkCommandPool commandPool, VkAllocationCallbacks* pAllocator);
    VkResult vkResetCommandPool(VkDevice device, VkCommandPool commandPool, VkCommandPoolResetFlags flags);
    VkResult vkAllocateCommandBuffers(VkDevice device, VkCommandBufferAllocateInfo* pAllocateInfo, VkCommandBuffer* pCommandBuffers);
    void vkFreeCommandBuffers(VkDevice device, VkCommandPool commandPool, uint32_t commandBufferCount, VkCommandBuffer* pCommandBuffers);
    VkResult vkBeginCommandBuffer(VkCommandBuffer commandBuffer, VkCommandBufferBeginInfo* pBeginInfo);
    VkResult vkEndCommandBuffer(VkCommandBuffer commandBuffer);
    VkResult vkResetCommandBuffer(VkCommandBuffer commandBuffer, VkCommandBufferResetFlags flags);
    void vkCmdBindPipeline(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline);
    void vkCmdSetAttachmentFeedbackLoopEnableEXT(VkCommandBuffer commandBuffer, VkImageAspectFlags aspectMask);
    void vkCmdSetViewport(VkCommandBuffer commandBuffer, uint32_t firstViewport, uint32_t viewportCount, VkViewport* pViewports);
    void vkCmdSetScissor(VkCommandBuffer commandBuffer, uint32_t firstScissor, uint32_t scissorCount, VkRect2D* pScissors);
    void vkCmdSetLineWidth(VkCommandBuffer commandBuffer, float lineWidth);
    void vkCmdSetDepthBias(VkCommandBuffer commandBuffer, float depthBiasConstantFactor, float depthBiasClamp, float depthBiasSlopeFactor);
    void vkCmdSetBlendConstants(VkCommandBuffer commandBuffer, float blendConstants[4]);
    void vkCmdSetDepthBounds(VkCommandBuffer commandBuffer, float minDepthBounds, float maxDepthBounds);
    void vkCmdSetStencilCompareMask(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t compareMask);
    void vkCmdSetStencilWriteMask(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t writeMask);
    void vkCmdSetStencilReference(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t reference);
    void vkCmdBindDescriptorSets(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t firstSet, uint32_t descriptorSetCount, VkDescriptorSet* pDescriptorSets, uint32_t dynamicOffsetCount, uint32_t* pDynamicOffsets);
    void vkCmdBindIndexBuffer(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkIndexType indexType);
    void vkCmdBindVertexBuffers(VkCommandBuffer commandBuffer, uint32_t firstBinding, uint32_t bindingCount, VkBuffer* pBuffers, VkDeviceSize* pOffsets);
    void vkCmdDraw(VkCommandBuffer commandBuffer, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
    void vkCmdDrawIndexed(VkCommandBuffer commandBuffer, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t vertexOffset, uint32_t firstInstance);
    void vkCmdDrawMultiEXT(VkCommandBuffer commandBuffer, uint32_t drawCount, VkMultiDrawInfoEXT* pVertexInfo, uint32_t instanceCount, uint32_t firstInstance, uint32_t stride);
    void vkCmdDrawMultiIndexedEXT(VkCommandBuffer commandBuffer, uint32_t drawCount, VkMultiDrawIndexedInfoEXT* pIndexInfo, uint32_t instanceCount, uint32_t firstInstance, uint32_t stride, int32_t* pVertexOffset);
    void vkCmdDrawIndirect(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride);
    void vkCmdDrawIndexedIndirect(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride);
    void vkCmdDispatch(VkCommandBuffer commandBuffer, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ);
    void vkCmdDispatchIndirect(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset);
    void vkCmdSubpassShadingHUAWEI(VkCommandBuffer commandBuffer);
    void vkCmdDrawClusterHUAWEI(VkCommandBuffer commandBuffer, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ);
    void vkCmdDrawClusterIndirectHUAWEI(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset);
    void vkCmdUpdatePipelineIndirectBufferNV(VkCommandBuffer commandBuffer, VkPipelineBindPoint           pipelineBindPoint, VkPipeline                    pipeline);
    void vkCmdCopyBuffer(VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkBuffer dstBuffer, uint32_t regionCount, VkBufferCopy* pRegions);
    void vkCmdCopyImage(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, VkImageCopy* pRegions);
    void vkCmdBlitImage(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, VkImageBlit* pRegions, VkFilter filter);
    void vkCmdCopyBufferToImage(VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, VkBufferImageCopy* pRegions);
    void vkCmdCopyImageToBuffer(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkBuffer dstBuffer, uint32_t regionCount, VkBufferImageCopy* pRegions);
    void vkCmdCopyMemoryIndirectNV(VkCommandBuffer commandBuffer, VkDeviceAddress copyBufferAddress, uint32_t copyCount, uint32_t stride);
    void vkCmdCopyMemoryIndirectKHR(VkCommandBuffer commandBuffer, VkCopyMemoryIndirectInfoKHR* pCopyMemoryIndirectInfo);
    void vkCmdCopyMemoryToImageIndirectNV(VkCommandBuffer commandBuffer, VkDeviceAddress copyBufferAddress, uint32_t copyCount, uint32_t stride, VkImage dstImage, VkImageLayout dstImageLayout, VkImageSubresourceLayers* pImageSubresources);
    void vkCmdCopyMemoryToImageIndirectKHR(VkCommandBuffer commandBuffer, VkCopyMemoryToImageIndirectInfoKHR* pCopyMemoryToImageIndirectInfo);
    void vkCmdUpdateBuffer(VkCommandBuffer commandBuffer, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize dataSize, void* pData);
    void vkCmdFillBuffer(VkCommandBuffer commandBuffer, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize size, uint32_t data);
    void vkCmdClearColorImage(VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, VkClearColorValue* pColor, uint32_t rangeCount, VkImageSubresourceRange* pRanges);
    void vkCmdClearDepthStencilImage(VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, VkClearDepthStencilValue* pDepthStencil, uint32_t rangeCount, VkImageSubresourceRange* pRanges);
    void vkCmdClearAttachments(VkCommandBuffer commandBuffer, uint32_t attachmentCount, VkClearAttachment* pAttachments, uint32_t rectCount, VkClearRect* pRects);
    void vkCmdResolveImage(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, VkImageResolve* pRegions);
    void vkCmdSetEvent(VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask);
    void vkCmdResetEvent(VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask);
    void vkCmdWaitEvents(VkCommandBuffer commandBuffer, uint32_t eventCount, VkEvent* pEvents, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, uint32_t memoryBarrierCount, VkMemoryBarrier* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, VkBufferMemoryBarrier* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, VkImageMemoryBarrier* pImageMemoryBarriers);
    void vkCmdPipelineBarrier(VkCommandBuffer commandBuffer, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, VkDependencyFlags dependencyFlags, uint32_t memoryBarrierCount, VkMemoryBarrier* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, VkBufferMemoryBarrier* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, VkImageMemoryBarrier* pImageMemoryBarriers);
    void vkCmdBeginQuery(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query, VkQueryControlFlags flags);
    void vkCmdEndQuery(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query);
    void vkCmdBeginConditionalRenderingEXT(VkCommandBuffer commandBuffer, VkConditionalRenderingBeginInfoEXT* pConditionalRenderingBegin);
    void vkCmdEndConditionalRenderingEXT(VkCommandBuffer commandBuffer);
    void vkCmdBeginCustomResolveEXT(VkCommandBuffer commandBuffer, VkBeginCustomResolveInfoEXT* pBeginCustomResolveInfo);
    void vkCmdResetQueryPool(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount);
    void vkCmdWriteTimestamp(VkCommandBuffer commandBuffer, VkPipelineStageFlagBits pipelineStage, VkQueryPool queryPool, uint32_t query);
    void vkCmdCopyQueryPoolResults(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize stride, VkQueryResultFlags flags);
    void vkCmdPushConstants(VkCommandBuffer commandBuffer, VkPipelineLayout layout, VkShaderStageFlags stageFlags, uint32_t offset, uint32_t size, void* pValues);
    void vkCmdBeginRenderPass(VkCommandBuffer commandBuffer, VkRenderPassBeginInfo* pRenderPassBegin, VkSubpassContents contents);
    void vkCmdNextSubpass(VkCommandBuffer commandBuffer, VkSubpassContents contents);
    void vkCmdEndRenderPass(VkCommandBuffer commandBuffer);
    void vkCmdExecuteCommands(VkCommandBuffer commandBuffer, uint32_t commandBufferCount, VkCommandBuffer* pCommandBuffers);
    VkResult vkCreateAndroidSurfaceKHR(VkInstance instance, VkAndroidSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkResult vkCreateSurfaceOHOS(VkInstance instance, VkSurfaceCreateInfoOHOS* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkResult vkGetPhysicalDeviceDisplayPropertiesKHR(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayPropertiesKHR* pProperties);
    VkResult vkGetPhysicalDeviceDisplayPlanePropertiesKHR(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayPlanePropertiesKHR* pProperties);
    VkResult vkGetDisplayPlaneSupportedDisplaysKHR(VkPhysicalDevice physicalDevice, uint32_t planeIndex, uint32_t* pDisplayCount, VkDisplayKHR* pDisplays);
    VkResult vkGetDisplayModePropertiesKHR(VkPhysicalDevice physicalDevice, VkDisplayKHR display, uint32_t* pPropertyCount, VkDisplayModePropertiesKHR* pProperties);
    VkResult vkCreateDisplayModeKHR(VkPhysicalDevice physicalDevice, VkDisplayKHR display, VkDisplayModeCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDisplayModeKHR* pMode);
    VkResult vkGetDisplayPlaneCapabilitiesKHR(VkPhysicalDevice physicalDevice, VkDisplayModeKHR mode, uint32_t planeIndex, VkDisplayPlaneCapabilitiesKHR* pCapabilities);
    VkResult vkCreateDisplayPlaneSurfaceKHR(VkInstance instance, VkDisplaySurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkResult vkCreateSharedSwapchainsKHR(VkDevice device, uint32_t swapchainCount, VkSwapchainCreateInfoKHR* pCreateInfos, VkAllocationCallbacks* pAllocator, VkSwapchainKHR* pSwapchains);
    void vkDestroySurfaceKHR(VkInstance instance, VkSurfaceKHR surface, VkAllocationCallbacks* pAllocator);
    VkResult vkGetPhysicalDeviceSurfaceSupportKHR(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, VkSurfaceKHR surface, VkBool32* pSupported);
    VkResult vkGetPhysicalDeviceSurfaceCapabilitiesKHR(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, VkSurfaceCapabilitiesKHR* pSurfaceCapabilities);
    VkResult vkGetPhysicalDeviceSurfaceFormatsKHR(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32_t* pSurfaceFormatCount, VkSurfaceFormatKHR* pSurfaceFormats);
    VkResult vkGetPhysicalDeviceSurfacePresentModesKHR(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32_t* pPresentModeCount, VkPresentModeKHR* pPresentModes);
    VkResult vkCreateSwapchainKHR(VkDevice device, VkSwapchainCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSwapchainKHR* pSwapchain);
    void vkDestroySwapchainKHR(VkDevice device, VkSwapchainKHR swapchain, VkAllocationCallbacks* pAllocator);
    VkResult vkGetSwapchainImagesKHR(VkDevice device, VkSwapchainKHR swapchain, uint32_t* pSwapchainImageCount, VkImage* pSwapchainImages);
    VkResult vkAcquireNextImageKHR(VkDevice device, VkSwapchainKHR swapchain, uint64_t timeout, VkSemaphore semaphore, VkFence fence, uint32_t* pImageIndex);
    VkResult vkQueuePresentKHR(VkQueue queue, VkPresentInfoKHR* pPresentInfo);
    VkResult vkCreateViSurfaceNN(VkInstance instance, VkViSurfaceCreateInfoNN* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkResult vkCreateWaylandSurfaceKHR(VkInstance instance, VkWaylandSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkBool32 vkGetPhysicalDeviceWaylandPresentationSupportKHR(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, struct wl_display* display);
    VkResult vkCreateUbmSurfaceSEC(VkInstance instance, VkUbmSurfaceCreateInfoSEC* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkBool32 vkGetPhysicalDeviceUbmPresentationSupportSEC(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, struct ubm_device* ubm_device);
    VkResult vkCreateWin32SurfaceKHR(VkInstance instance, VkWin32SurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkBool32 vkGetPhysicalDeviceWin32PresentationSupportKHR(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex);
    VkResult vkCreateXlibSurfaceKHR(VkInstance instance, VkXlibSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkBool32 vkGetPhysicalDeviceXlibPresentationSupportKHR(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, Display* dpy, VisualID visualID);
    VkResult vkCreateXcbSurfaceKHR(VkInstance instance, VkXcbSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkBool32 vkGetPhysicalDeviceXcbPresentationSupportKHR(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, xcb_connection_t* connection, xcb_visualid_t visual_id);
    VkResult vkCreateDirectFBSurfaceEXT(VkInstance instance, VkDirectFBSurfaceCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkBool32 vkGetPhysicalDeviceDirectFBPresentationSupportEXT(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, IDirectFB* dfb);
    VkResult vkCreateImagePipeSurfaceFUCHSIA(VkInstance instance, VkImagePipeSurfaceCreateInfoFUCHSIA* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkResult vkCreateStreamDescriptorSurfaceGGP(VkInstance instance, VkStreamDescriptorSurfaceCreateInfoGGP* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkResult vkCreateScreenSurfaceQNX(VkInstance instance, VkScreenSurfaceCreateInfoQNX* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkBool32 vkGetPhysicalDeviceScreenPresentationSupportQNX(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, struct _screen_window* window);
    VkResult vkCreateDebugReportCallbackEXT(VkInstance instance, VkDebugReportCallbackCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDebugReportCallbackEXT* pCallback);
    void vkDestroyDebugReportCallbackEXT(VkInstance instance, VkDebugReportCallbackEXT callback, VkAllocationCallbacks* pAllocator);
    void vkDebugReportMessageEXT(VkInstance instance, VkDebugReportFlagsEXT flags, VkDebugReportObjectTypeEXT objectType, uint64_t object, size_t location, int32_t messageCode, char* pLayerPrefix, char* pMessage);
    VkResult vkDebugMarkerSetObjectNameEXT(VkDevice device, VkDebugMarkerObjectNameInfoEXT* pNameInfo);
    VkResult vkDebugMarkerSetObjectTagEXT(VkDevice device, VkDebugMarkerObjectTagInfoEXT* pTagInfo);
    void vkCmdDebugMarkerBeginEXT(VkCommandBuffer commandBuffer, VkDebugMarkerMarkerInfoEXT* pMarkerInfo);
    void vkCmdDebugMarkerEndEXT(VkCommandBuffer commandBuffer);
    void vkCmdDebugMarkerInsertEXT(VkCommandBuffer commandBuffer, VkDebugMarkerMarkerInfoEXT* pMarkerInfo);
    VkResult vkGetPhysicalDeviceExternalImageFormatPropertiesNV(VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkImageTiling tiling, VkImageUsageFlags usage, VkImageCreateFlags flags, VkExternalMemoryHandleTypeFlagsNV externalHandleType, VkExternalImageFormatPropertiesNV* pExternalImageFormatProperties);
    VkResult vkGetMemoryWin32HandleNV(VkDevice device, VkDeviceMemory memory, VkExternalMemoryHandleTypeFlagsNV handleType, HANDLE* pHandle);
    void vkCmdExecuteGeneratedCommandsNV(VkCommandBuffer commandBuffer, VkBool32 isPreprocessed, VkGeneratedCommandsInfoNV* pGeneratedCommandsInfo);
    void vkCmdPreprocessGeneratedCommandsNV(VkCommandBuffer commandBuffer, VkGeneratedCommandsInfoNV* pGeneratedCommandsInfo);
    void vkCmdBindPipelineShaderGroupNV(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline, uint32_t groupIndex);
    void vkGetGeneratedCommandsMemoryRequirementsNV(VkDevice device, VkGeneratedCommandsMemoryRequirementsInfoNV* pInfo, VkMemoryRequirements2* pMemoryRequirements);
    VkResult vkCreateIndirectCommandsLayoutNV(VkDevice device, VkIndirectCommandsLayoutCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkIndirectCommandsLayoutNV* pIndirectCommandsLayout);
    void vkDestroyIndirectCommandsLayoutNV(VkDevice device, VkIndirectCommandsLayoutNV indirectCommandsLayout, VkAllocationCallbacks* pAllocator);
    void vkCmdExecuteGeneratedCommandsEXT(VkCommandBuffer commandBuffer, VkBool32 isPreprocessed, VkGeneratedCommandsInfoEXT* pGeneratedCommandsInfo);
    void vkCmdPreprocessGeneratedCommandsEXT(VkCommandBuffer commandBuffer, VkGeneratedCommandsInfoEXT* pGeneratedCommandsInfo, VkCommandBuffer stateCommandBuffer);
    void vkGetGeneratedCommandsMemoryRequirementsEXT(VkDevice device, VkGeneratedCommandsMemoryRequirementsInfoEXT* pInfo, VkMemoryRequirements2* pMemoryRequirements);
    VkResult vkCreateIndirectCommandsLayoutEXT(VkDevice device, VkIndirectCommandsLayoutCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkIndirectCommandsLayoutEXT* pIndirectCommandsLayout);
    void vkDestroyIndirectCommandsLayoutEXT(VkDevice device, VkIndirectCommandsLayoutEXT indirectCommandsLayout, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateIndirectExecutionSetEXT(VkDevice device, VkIndirectExecutionSetCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkIndirectExecutionSetEXT* pIndirectExecutionSet);
    void vkDestroyIndirectExecutionSetEXT(VkDevice device, VkIndirectExecutionSetEXT indirectExecutionSet, VkAllocationCallbacks* pAllocator);
    void vkUpdateIndirectExecutionSetPipelineEXT(VkDevice device, VkIndirectExecutionSetEXT indirectExecutionSet, uint32_t executionSetWriteCount, VkWriteIndirectExecutionSetPipelineEXT* pExecutionSetWrites);
    void vkUpdateIndirectExecutionSetShaderEXT(VkDevice device, VkIndirectExecutionSetEXT indirectExecutionSet, uint32_t executionSetWriteCount, VkWriteIndirectExecutionSetShaderEXT* pExecutionSetWrites);
    void vkGetPhysicalDeviceFeatures2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures2* pFeatures);
    void vkGetPhysicalDeviceProperties2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties2* pProperties);
    void vkGetPhysicalDeviceFormatProperties2(VkPhysicalDevice physicalDevice, VkFormat format, VkFormatProperties2* pFormatProperties);
    VkResult vkGetPhysicalDeviceImageFormatProperties2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceImageFormatInfo2* pImageFormatInfo, VkImageFormatProperties2* pImageFormatProperties);
    void vkGetPhysicalDeviceQueueFamilyProperties2(VkPhysicalDevice physicalDevice, uint32_t* pQueueFamilyPropertyCount, VkQueueFamilyProperties2* pQueueFamilyProperties);
    void vkGetPhysicalDeviceMemoryProperties2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceMemoryProperties2* pMemoryProperties);
    void vkGetPhysicalDeviceSparseImageFormatProperties2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSparseImageFormatInfo2* pFormatInfo, uint32_t* pPropertyCount, VkSparseImageFormatProperties2* pProperties);
    void vkCmdPushDescriptorSet(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t set, uint32_t descriptorWriteCount, VkWriteDescriptorSet* pDescriptorWrites);
    void vkTrimCommandPool(VkDevice device, VkCommandPool commandPool, VkCommandPoolTrimFlags flags);
    void vkGetPhysicalDeviceExternalBufferProperties(VkPhysicalDevice physicalDevice, VkPhysicalDeviceExternalBufferInfo* pExternalBufferInfo, VkExternalBufferProperties* pExternalBufferProperties);
    VkResult vkGetMemoryWin32HandleKHR(VkDevice device, VkMemoryGetWin32HandleInfoKHR* pGetWin32HandleInfo, HANDLE* pHandle);
    VkResult vkGetMemoryWin32HandlePropertiesKHR(VkDevice device, VkExternalMemoryHandleTypeFlagBits handleType, HANDLE handle, VkMemoryWin32HandlePropertiesKHR* pMemoryWin32HandleProperties);
    VkResult vkGetMemoryFdKHR(VkDevice device, VkMemoryGetFdInfoKHR* pGetFdInfo, int* pFd);
    VkResult vkGetMemoryFdPropertiesKHR(VkDevice device, VkExternalMemoryHandleTypeFlagBits handleType, int fd, VkMemoryFdPropertiesKHR* pMemoryFdProperties);
    VkResult vkGetMemoryZirconHandleFUCHSIA(VkDevice device, VkMemoryGetZirconHandleInfoFUCHSIA* pGetZirconHandleInfo, zx_handle_t* pZirconHandle);
    VkResult vkGetMemoryZirconHandlePropertiesFUCHSIA(VkDevice device, VkExternalMemoryHandleTypeFlagBits handleType, zx_handle_t zirconHandle, VkMemoryZirconHandlePropertiesFUCHSIA* pMemoryZirconHandleProperties);
    VkResult vkGetMemoryRemoteAddressNV(VkDevice device, VkMemoryGetRemoteAddressInfoNV* pMemoryGetRemoteAddressInfo, VkRemoteAddressNV* pAddress);
    VkResult vkGetMemorySciBufNV(VkDevice device, VkMemoryGetSciBufInfoNV* pGetSciBufInfo, NvSciBufObj* pHandle);
    VkResult vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV(VkPhysicalDevice physicalDevice, VkExternalMemoryHandleTypeFlagBits handleType, NvSciBufObj handle, VkMemorySciBufPropertiesNV* pMemorySciBufProperties);
    VkResult vkGetPhysicalDeviceSciBufAttributesNV(VkPhysicalDevice physicalDevice, NvSciBufAttrList pAttributes);
    void vkGetPhysicalDeviceExternalSemaphoreProperties(VkPhysicalDevice physicalDevice, VkPhysicalDeviceExternalSemaphoreInfo* pExternalSemaphoreInfo, VkExternalSemaphoreProperties* pExternalSemaphoreProperties);
    VkResult vkGetSemaphoreWin32HandleKHR(VkDevice device, VkSemaphoreGetWin32HandleInfoKHR* pGetWin32HandleInfo, HANDLE* pHandle);
    VkResult vkImportSemaphoreWin32HandleKHR(VkDevice device, VkImportSemaphoreWin32HandleInfoKHR* pImportSemaphoreWin32HandleInfo);
    VkResult vkGetSemaphoreFdKHR(VkDevice device, VkSemaphoreGetFdInfoKHR* pGetFdInfo, int* pFd);
    VkResult vkImportSemaphoreFdKHR(VkDevice device, VkImportSemaphoreFdInfoKHR* pImportSemaphoreFdInfo);
    VkResult vkGetSemaphoreZirconHandleFUCHSIA(VkDevice device, VkSemaphoreGetZirconHandleInfoFUCHSIA* pGetZirconHandleInfo, zx_handle_t* pZirconHandle);
    VkResult vkImportSemaphoreZirconHandleFUCHSIA(VkDevice device, VkImportSemaphoreZirconHandleInfoFUCHSIA* pImportSemaphoreZirconHandleInfo);
    void vkGetPhysicalDeviceExternalFenceProperties(VkPhysicalDevice physicalDevice, VkPhysicalDeviceExternalFenceInfo* pExternalFenceInfo, VkExternalFenceProperties* pExternalFenceProperties);
    VkResult vkGetFenceWin32HandleKHR(VkDevice device, VkFenceGetWin32HandleInfoKHR* pGetWin32HandleInfo, HANDLE* pHandle);
    VkResult vkImportFenceWin32HandleKHR(VkDevice device, VkImportFenceWin32HandleInfoKHR* pImportFenceWin32HandleInfo);
    VkResult vkGetFenceFdKHR(VkDevice device, VkFenceGetFdInfoKHR* pGetFdInfo, int* pFd);
    VkResult vkImportFenceFdKHR(VkDevice device, VkImportFenceFdInfoKHR* pImportFenceFdInfo);
    VkResult vkGetFenceSciSyncFenceNV(VkDevice device, VkFenceGetSciSyncInfoNV* pGetSciSyncHandleInfo, void* pHandle);
    VkResult vkGetFenceSciSyncObjNV(VkDevice device, VkFenceGetSciSyncInfoNV* pGetSciSyncHandleInfo, void* pHandle);
    VkResult vkImportFenceSciSyncFenceNV(VkDevice device, VkImportFenceSciSyncInfoNV* pImportFenceSciSyncInfo);
    VkResult vkImportFenceSciSyncObjNV(VkDevice device, VkImportFenceSciSyncInfoNV* pImportFenceSciSyncInfo);
    VkResult vkGetSemaphoreSciSyncObjNV(VkDevice device, VkSemaphoreGetSciSyncInfoNV* pGetSciSyncInfo, void* pHandle);
    VkResult vkImportSemaphoreSciSyncObjNV(VkDevice device, VkImportSemaphoreSciSyncInfoNV* pImportSemaphoreSciSyncInfo);
    VkResult vkGetPhysicalDeviceSciSyncAttributesNV(VkPhysicalDevice physicalDevice, VkSciSyncAttributesInfoNV* pSciSyncAttributesInfo, NvSciSyncAttrList pAttributes);
    VkResult vkCreateSemaphoreSciSyncPoolNV(VkDevice device, VkSemaphoreSciSyncPoolCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSemaphoreSciSyncPoolNV* pSemaphorePool);
    void vkDestroySemaphoreSciSyncPoolNV(VkDevice device, VkSemaphoreSciSyncPoolNV semaphorePool, VkAllocationCallbacks* pAllocator);
    VkResult vkReleaseDisplayEXT(VkPhysicalDevice physicalDevice, VkDisplayKHR display);
    VkResult vkAcquireXlibDisplayEXT(VkPhysicalDevice physicalDevice, Display* dpy, VkDisplayKHR display);
    VkResult vkGetRandROutputDisplayEXT(VkPhysicalDevice physicalDevice, Display* dpy, RROutput rrOutput, VkDisplayKHR* pDisplay);
    VkResult vkAcquireWinrtDisplayNV(VkPhysicalDevice physicalDevice, VkDisplayKHR display);
    VkResult vkGetWinrtDisplayNV(VkPhysicalDevice physicalDevice, uint32_t deviceRelativeId, VkDisplayKHR* pDisplay);
    VkResult vkDisplayPowerControlEXT(VkDevice device, VkDisplayKHR display, VkDisplayPowerInfoEXT* pDisplayPowerInfo);
    VkResult vkRegisterDeviceEventEXT(VkDevice device, VkDeviceEventInfoEXT* pDeviceEventInfo, VkAllocationCallbacks* pAllocator, VkFence* pFence);
    VkResult vkRegisterDisplayEventEXT(VkDevice device, VkDisplayKHR display, VkDisplayEventInfoEXT* pDisplayEventInfo, VkAllocationCallbacks* pAllocator, VkFence* pFence);
    VkResult vkGetSwapchainCounterEXT(VkDevice device, VkSwapchainKHR swapchain, VkSurfaceCounterFlagBitsEXT counter, uint64_t* pCounterValue);
    VkResult vkGetPhysicalDeviceSurfaceCapabilities2EXT(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, VkSurfaceCapabilities2EXT* pSurfaceCapabilities);
    VkResult vkEnumeratePhysicalDeviceGroups(VkInstance instance, uint32_t* pPhysicalDeviceGroupCount, VkPhysicalDeviceGroupProperties* pPhysicalDeviceGroupProperties);
    void vkGetDeviceGroupPeerMemoryFeatures(VkDevice device, uint32_t heapIndex, uint32_t localDeviceIndex, uint32_t remoteDeviceIndex, VkPeerMemoryFeatureFlags* pPeerMemoryFeatures);
    VkResult vkBindBufferMemory2(VkDevice device, uint32_t bindInfoCount, VkBindBufferMemoryInfo* pBindInfos);
    VkResult vkBindImageMemory2(VkDevice device, uint32_t bindInfoCount, VkBindImageMemoryInfo* pBindInfos);
    void vkCmdSetDeviceMask(VkCommandBuffer commandBuffer, uint32_t deviceMask);
    VkResult vkGetDeviceGroupPresentCapabilitiesKHR(VkDevice device, VkDeviceGroupPresentCapabilitiesKHR* pDeviceGroupPresentCapabilities);
    VkResult vkGetDeviceGroupSurfacePresentModesKHR(VkDevice device, VkSurfaceKHR surface, VkDeviceGroupPresentModeFlagsKHR* pModes);
    VkResult vkAcquireNextImage2KHR(VkDevice device, VkAcquireNextImageInfoKHR* pAcquireInfo, uint32_t* pImageIndex);
    void vkCmdDispatchBase(VkCommandBuffer commandBuffer, uint32_t baseGroupX, uint32_t baseGroupY, uint32_t baseGroupZ, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ);
    VkResult vkGetPhysicalDevicePresentRectanglesKHR(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32_t* pRectCount, VkRect2D* pRects);
    VkResult vkCreateDescriptorUpdateTemplate(VkDevice device, VkDescriptorUpdateTemplateCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDescriptorUpdateTemplate* pDescriptorUpdateTemplate);
    void vkDestroyDescriptorUpdateTemplate(VkDevice device, VkDescriptorUpdateTemplate descriptorUpdateTemplate, VkAllocationCallbacks* pAllocator);
    void vkUpdateDescriptorSetWithTemplate(VkDevice device, VkDescriptorSet descriptorSet, VkDescriptorUpdateTemplate descriptorUpdateTemplate, void* pData);
    void vkCmdPushDescriptorSetWithTemplate(VkCommandBuffer commandBuffer, VkDescriptorUpdateTemplate descriptorUpdateTemplate, VkPipelineLayout layout, uint32_t set, void* pData);
    void vkSetHdrMetadataEXT(VkDevice device, uint32_t swapchainCount, VkSwapchainKHR* pSwapchains, VkHdrMetadataEXT* pMetadata);
    VkResult vkGetSwapchainStatusKHR(VkDevice device, VkSwapchainKHR swapchain);
    VkResult vkGetRefreshCycleDurationGOOGLE(VkDevice device, VkSwapchainKHR swapchain, VkRefreshCycleDurationGOOGLE* pDisplayTimingProperties);
    VkResult vkGetPastPresentationTimingGOOGLE(VkDevice device, VkSwapchainKHR swapchain, uint32_t* pPresentationTimingCount, VkPastPresentationTimingGOOGLE* pPresentationTimings);
    VkResult vkCreateIOSSurfaceMVK(VkInstance instance, VkIOSSurfaceCreateInfoMVK* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkResult vkCreateMacOSSurfaceMVK(VkInstance instance, VkMacOSSurfaceCreateInfoMVK* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkResult vkCreateMetalSurfaceEXT(VkInstance instance, VkMetalSurfaceCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    void vkCmdSetViewportWScalingNV(VkCommandBuffer commandBuffer, uint32_t firstViewport, uint32_t viewportCount, VkViewportWScalingNV* pViewportWScalings);
    void vkCmdSetDiscardRectangleEXT(VkCommandBuffer commandBuffer, uint32_t firstDiscardRectangle, uint32_t discardRectangleCount, VkRect2D* pDiscardRectangles);
    void vkCmdSetDiscardRectangleEnableEXT(VkCommandBuffer commandBuffer, VkBool32 discardRectangleEnable);
    void vkCmdSetDiscardRectangleModeEXT(VkCommandBuffer commandBuffer, VkDiscardRectangleModeEXT discardRectangleMode);
    void vkCmdSetSampleLocationsEXT(VkCommandBuffer commandBuffer, VkSampleLocationsInfoEXT* pSampleLocationsInfo);
    void vkGetPhysicalDeviceMultisamplePropertiesEXT(VkPhysicalDevice physicalDevice, VkSampleCountFlagBits samples, VkMultisamplePropertiesEXT* pMultisampleProperties);
    VkResult vkGetPhysicalDeviceSurfaceCapabilities2KHR(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, VkSurfaceCapabilities2KHR* pSurfaceCapabilities);
    VkResult vkGetPhysicalDeviceSurfaceFormats2KHR(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, uint32_t* pSurfaceFormatCount, VkSurfaceFormat2KHR* pSurfaceFormats);
    VkResult vkGetPhysicalDeviceDisplayProperties2KHR(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayProperties2KHR* pProperties);
    VkResult vkGetPhysicalDeviceDisplayPlaneProperties2KHR(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayPlaneProperties2KHR* pProperties);
    VkResult vkGetDisplayModeProperties2KHR(VkPhysicalDevice physicalDevice, VkDisplayKHR display, uint32_t* pPropertyCount, VkDisplayModeProperties2KHR* pProperties);
    VkResult vkGetDisplayPlaneCapabilities2KHR(VkPhysicalDevice physicalDevice, VkDisplayPlaneInfo2KHR* pDisplayPlaneInfo, VkDisplayPlaneCapabilities2KHR* pCapabilities);
    void vkGetBufferMemoryRequirements2(VkDevice device, VkBufferMemoryRequirementsInfo2* pInfo, VkMemoryRequirements2* pMemoryRequirements);
    void vkGetImageMemoryRequirements2(VkDevice device, VkImageMemoryRequirementsInfo2* pInfo, VkMemoryRequirements2* pMemoryRequirements);
    void vkGetImageSparseMemoryRequirements2(VkDevice device, VkImageSparseMemoryRequirementsInfo2* pInfo, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements2* pSparseMemoryRequirements);
    void vkGetDeviceBufferMemoryRequirements(VkDevice device, VkDeviceBufferMemoryRequirements* pInfo, VkMemoryRequirements2* pMemoryRequirements);
    void vkGetDeviceImageMemoryRequirements(VkDevice device, VkDeviceImageMemoryRequirements* pInfo, VkMemoryRequirements2* pMemoryRequirements);
    void vkGetDeviceImageSparseMemoryRequirements(VkDevice device, VkDeviceImageMemoryRequirements* pInfo, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements2* pSparseMemoryRequirements);
    VkResult vkCreateSamplerYcbcrConversion(VkDevice device, VkSamplerYcbcrConversionCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSamplerYcbcrConversion* pYcbcrConversion);
    void vkDestroySamplerYcbcrConversion(VkDevice device, VkSamplerYcbcrConversion ycbcrConversion, VkAllocationCallbacks* pAllocator);
    void vkGetDeviceQueue2(VkDevice device, VkDeviceQueueInfo2* pQueueInfo, VkQueue* pQueue);
    VkResult vkCreateValidationCacheEXT(VkDevice device, VkValidationCacheCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkValidationCacheEXT* pValidationCache);
    void vkDestroyValidationCacheEXT(VkDevice device, VkValidationCacheEXT validationCache, VkAllocationCallbacks* pAllocator);
    VkResult vkGetValidationCacheDataEXT(VkDevice device, VkValidationCacheEXT validationCache, size_t* pDataSize, void* pData);
    VkResult vkMergeValidationCachesEXT(VkDevice device, VkValidationCacheEXT dstCache, uint32_t srcCacheCount, VkValidationCacheEXT* pSrcCaches);
    void vkGetDescriptorSetLayoutSupport(VkDevice device, VkDescriptorSetLayoutCreateInfo* pCreateInfo, VkDescriptorSetLayoutSupport* pSupport);
    VkResult vkGetSwapchainGrallocUsageANDROID(VkDevice device, VkFormat format, VkImageUsageFlags imageUsage, int* grallocUsage);
    VkResult vkGetSwapchainGrallocUsage2ANDROID(VkDevice device, VkFormat format, VkImageUsageFlags imageUsage, VkSwapchainImageUsageFlagsANDROID swapchainImageUsage, uint64_t* grallocConsumerUsage, uint64_t* grallocProducerUsage);
    VkResult vkAcquireImageANDROID(VkDevice device, VkImage image, int nativeFenceFd, VkSemaphore semaphore, VkFence fence);
    VkResult vkQueueSignalReleaseImageANDROID(VkQueue queue, uint32_t waitSemaphoreCount, VkSemaphore* pWaitSemaphores, VkImage image, int* pNativeFenceFd);
    VkResult vkGetShaderInfoAMD(VkDevice device, VkPipeline pipeline, VkShaderStageFlagBits shaderStage, VkShaderInfoTypeAMD infoType, size_t* pInfoSize, void* pInfo);
    void vkSetLocalDimmingAMD(VkDevice device, VkSwapchainKHR swapChain, VkBool32 localDimmingEnable);
    VkResult vkGetPhysicalDeviceCalibrateableTimeDomainsKHR(VkPhysicalDevice physicalDevice, uint32_t* pTimeDomainCount, VkTimeDomainKHR* pTimeDomains);
    VkResult vkGetCalibratedTimestampsKHR(VkDevice device, uint32_t timestampCount, VkCalibratedTimestampInfoKHR* pTimestampInfos, uint64_t* pTimestamps, uint64_t* pMaxDeviation);
    VkResult vkSetDebugUtilsObjectNameEXT(VkDevice device, VkDebugUtilsObjectNameInfoEXT* pNameInfo);
    VkResult vkSetDebugUtilsObjectTagEXT(VkDevice device, VkDebugUtilsObjectTagInfoEXT* pTagInfo);
    void vkQueueBeginDebugUtilsLabelEXT(VkQueue queue, VkDebugUtilsLabelEXT* pLabelInfo);
    void vkQueueEndDebugUtilsLabelEXT(VkQueue queue);
    void vkQueueInsertDebugUtilsLabelEXT(VkQueue queue, VkDebugUtilsLabelEXT* pLabelInfo);
    void vkCmdBeginDebugUtilsLabelEXT(VkCommandBuffer commandBuffer, VkDebugUtilsLabelEXT* pLabelInfo);
    void vkCmdEndDebugUtilsLabelEXT(VkCommandBuffer commandBuffer);
    void vkCmdInsertDebugUtilsLabelEXT(VkCommandBuffer commandBuffer, VkDebugUtilsLabelEXT* pLabelInfo);
    VkResult vkCreateDebugUtilsMessengerEXT(VkInstance instance, VkDebugUtilsMessengerCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDebugUtilsMessengerEXT* pMessenger);
    void vkDestroyDebugUtilsMessengerEXT(VkInstance instance, VkDebugUtilsMessengerEXT messenger, VkAllocationCallbacks* pAllocator);
    void vkSubmitDebugUtilsMessageEXT(VkInstance instance, VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity, VkDebugUtilsMessageTypeFlagsEXT messageTypes, VkDebugUtilsMessengerCallbackDataEXT* pCallbackData);
    VkResult vkGetMemoryHostPointerPropertiesEXT(VkDevice device, VkExternalMemoryHandleTypeFlagBits handleType, void* pHostPointer, VkMemoryHostPointerPropertiesEXT* pMemoryHostPointerProperties);
    void vkCmdWriteBufferMarkerAMD(VkCommandBuffer commandBuffer, VkPipelineStageFlagBits pipelineStage, VkBuffer dstBuffer, VkDeviceSize dstOffset, uint32_t marker);
    VkResult vkCreateRenderPass2(VkDevice device, VkRenderPassCreateInfo2* pCreateInfo, VkAllocationCallbacks* pAllocator, VkRenderPass* pRenderPass);
    void vkCmdBeginRenderPass2(VkCommandBuffer commandBuffer, VkRenderPassBeginInfo*      pRenderPassBegin, VkSubpassBeginInfo*      pSubpassBeginInfo);
    void vkCmdNextSubpass2(VkCommandBuffer commandBuffer, VkSubpassBeginInfo*      pSubpassBeginInfo, VkSubpassEndInfo*        pSubpassEndInfo);
    void vkCmdEndRenderPass2(VkCommandBuffer commandBuffer, VkSubpassEndInfo*        pSubpassEndInfo);
    VkResult vkGetSemaphoreCounterValue(VkDevice device, VkSemaphore semaphore, uint64_t* pValue);
    VkResult vkWaitSemaphores(VkDevice device, VkSemaphoreWaitInfo* pWaitInfo, uint64_t timeout);
    VkResult vkSignalSemaphore(VkDevice device, VkSemaphoreSignalInfo* pSignalInfo);
    VkResult vkGetAndroidHardwareBufferPropertiesANDROID(VkDevice device, struct AHardwareBuffer* buffer, VkAndroidHardwareBufferPropertiesANDROID* pProperties);
    VkResult vkGetMemoryAndroidHardwareBufferANDROID(VkDevice device, VkMemoryGetAndroidHardwareBufferInfoANDROID* pInfo, struct AHardwareBuffer** pBuffer);
    void vkCmdDrawIndirectCount(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride);
    void vkCmdDrawIndexedIndirectCount(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride);
    void vkCmdSetCheckpointNV(VkCommandBuffer commandBuffer, void* pCheckpointMarker);
    void vkGetQueueCheckpointDataNV(VkQueue queue, uint32_t* pCheckpointDataCount, VkCheckpointDataNV* pCheckpointData);
    void vkCmdBindTransformFeedbackBuffersEXT(VkCommandBuffer commandBuffer, uint32_t firstBinding, uint32_t bindingCount, VkBuffer* pBuffers, VkDeviceSize* pOffsets, VkDeviceSize* pSizes);
    void vkCmdBeginTransformFeedbackEXT(VkCommandBuffer commandBuffer, uint32_t firstCounterBuffer, uint32_t counterBufferCount, VkBuffer* pCounterBuffers, VkDeviceSize* pCounterBufferOffsets);
    void vkCmdEndTransformFeedbackEXT(VkCommandBuffer commandBuffer, uint32_t firstCounterBuffer, uint32_t counterBufferCount, VkBuffer* pCounterBuffers, VkDeviceSize* pCounterBufferOffsets);
    void vkCmdBeginQueryIndexedEXT(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query, VkQueryControlFlags flags, uint32_t index);
    void vkCmdEndQueryIndexedEXT(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query, uint32_t index);
    void vkCmdDrawIndirectByteCountEXT(VkCommandBuffer commandBuffer, uint32_t instanceCount, uint32_t firstInstance, VkBuffer counterBuffer, VkDeviceSize counterBufferOffset, uint32_t counterOffset, uint32_t vertexStride);
    void vkCmdSetExclusiveScissorNV(VkCommandBuffer commandBuffer, uint32_t firstExclusiveScissor, uint32_t exclusiveScissorCount, VkRect2D* pExclusiveScissors);
    void vkCmdSetExclusiveScissorEnableNV(VkCommandBuffer commandBuffer, uint32_t firstExclusiveScissor, uint32_t exclusiveScissorCount, VkBool32* pExclusiveScissorEnables);
    void vkCmdBindShadingRateImageNV(VkCommandBuffer commandBuffer, VkImageView imageView, VkImageLayout imageLayout);
    void vkCmdSetViewportShadingRatePaletteNV(VkCommandBuffer commandBuffer, uint32_t firstViewport, uint32_t viewportCount, VkShadingRatePaletteNV* pShadingRatePalettes);
    void vkCmdSetCoarseSampleOrderNV(VkCommandBuffer commandBuffer, VkCoarseSampleOrderTypeNV sampleOrderType, uint32_t customSampleOrderCount, VkCoarseSampleOrderCustomNV* pCustomSampleOrders);
    void vkCmdDrawMeshTasksNV(VkCommandBuffer commandBuffer, uint32_t taskCount, uint32_t firstTask);
    void vkCmdDrawMeshTasksIndirectNV(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride);
    void vkCmdDrawMeshTasksIndirectCountNV(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride);
    void vkCmdDrawMeshTasksEXT(VkCommandBuffer commandBuffer, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ);
    void vkCmdDrawMeshTasksIndirectEXT(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride);
    void vkCmdDrawMeshTasksIndirectCountEXT(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride);
    VkResult vkCompileDeferredNV(VkDevice device, VkPipeline pipeline, uint32_t shader);
    VkResult vkCreateAccelerationStructureNV(VkDevice device, VkAccelerationStructureCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkAccelerationStructureNV* pAccelerationStructure);
    void vkCmdBindInvocationMaskHUAWEI(VkCommandBuffer commandBuffer, VkImageView imageView, VkImageLayout imageLayout);
    void vkDestroyAccelerationStructureKHR(VkDevice device, VkAccelerationStructureKHR accelerationStructure, VkAllocationCallbacks* pAllocator);
    void vkDestroyAccelerationStructureNV(VkDevice device, VkAccelerationStructureNV accelerationStructure, VkAllocationCallbacks* pAllocator);
    void vkGetAccelerationStructureMemoryRequirementsNV(VkDevice device, VkAccelerationStructureMemoryRequirementsInfoNV* pInfo, VkMemoryRequirements2KHR* pMemoryRequirements);
    VkResult vkBindAccelerationStructureMemoryNV(VkDevice device, uint32_t bindInfoCount, VkBindAccelerationStructureMemoryInfoNV* pBindInfos);
    void vkCmdCopyAccelerationStructureNV(VkCommandBuffer commandBuffer, VkAccelerationStructureNV dst, VkAccelerationStructureNV src, VkCopyAccelerationStructureModeKHR mode);
    void vkCmdCopyAccelerationStructureKHR(VkCommandBuffer commandBuffer, VkCopyAccelerationStructureInfoKHR* pInfo);
    VkResult vkCopyAccelerationStructureKHR(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyAccelerationStructureInfoKHR* pInfo);
    void vkCmdCopyAccelerationStructureToMemoryKHR(VkCommandBuffer commandBuffer, VkCopyAccelerationStructureToMemoryInfoKHR* pInfo);
    VkResult vkCopyAccelerationStructureToMemoryKHR(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyAccelerationStructureToMemoryInfoKHR* pInfo);
    void vkCmdCopyMemoryToAccelerationStructureKHR(VkCommandBuffer commandBuffer, VkCopyMemoryToAccelerationStructureInfoKHR* pInfo);
    VkResult vkCopyMemoryToAccelerationStructureKHR(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMemoryToAccelerationStructureInfoKHR* pInfo);
    void vkCmdWriteAccelerationStructuresPropertiesKHR(VkCommandBuffer commandBuffer, uint32_t accelerationStructureCount, VkAccelerationStructureKHR* pAccelerationStructures, VkQueryType queryType, VkQueryPool queryPool, uint32_t firstQuery);
    void vkCmdWriteAccelerationStructuresPropertiesNV(VkCommandBuffer commandBuffer, uint32_t accelerationStructureCount, VkAccelerationStructureNV* pAccelerationStructures, VkQueryType queryType, VkQueryPool queryPool, uint32_t firstQuery);
    void vkCmdBuildAccelerationStructureNV(VkCommandBuffer commandBuffer, VkAccelerationStructureInfoNV* pInfo, VkBuffer instanceData, VkDeviceSize instanceOffset, VkBool32 update, VkAccelerationStructureNV dst, VkAccelerationStructureNV src, VkBuffer scratch, VkDeviceSize scratchOffset);
    VkResult vkWriteAccelerationStructuresPropertiesKHR(VkDevice device, uint32_t accelerationStructureCount, VkAccelerationStructureKHR* pAccelerationStructures, VkQueryType  queryType, size_t       dataSize, void* pData, size_t stride);
    void vkCmdTraceRaysKHR(VkCommandBuffer commandBuffer, VkStridedDeviceAddressRegionKHR* pRaygenShaderBindingTable, VkStridedDeviceAddressRegionKHR* pMissShaderBindingTable, VkStridedDeviceAddressRegionKHR* pHitShaderBindingTable, VkStridedDeviceAddressRegionKHR* pCallableShaderBindingTable, uint32_t width, uint32_t height, uint32_t depth);
    void vkCmdTraceRaysNV(VkCommandBuffer commandBuffer, VkBuffer raygenShaderBindingTableBuffer, VkDeviceSize raygenShaderBindingOffset, VkBuffer missShaderBindingTableBuffer, VkDeviceSize missShaderBindingOffset, VkDeviceSize missShaderBindingStride, VkBuffer hitShaderBindingTableBuffer, VkDeviceSize hitShaderBindingOffset, VkDeviceSize hitShaderBindingStride, VkBuffer callableShaderBindingTableBuffer, VkDeviceSize callableShaderBindingOffset, VkDeviceSize callableShaderBindingStride, uint32_t width, uint32_t height, uint32_t depth);
    VkResult vkGetRayTracingShaderGroupHandlesKHR(VkDevice device, VkPipeline pipeline, uint32_t firstGroup, uint32_t groupCount, size_t dataSize, void* pData);
    VkResult vkGetRayTracingCaptureReplayShaderGroupHandlesKHR(VkDevice device, VkPipeline pipeline, uint32_t firstGroup, uint32_t groupCount, size_t dataSize, void* pData);
    VkResult vkGetAccelerationStructureHandleNV(VkDevice device, VkAccelerationStructureNV accelerationStructure, size_t dataSize, void* pData);
    VkResult vkCreateRayTracingPipelinesNV(VkDevice device, VkPipelineCache pipelineCache, uint32_t createInfoCount, VkRayTracingPipelineCreateInfoNV* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
    VkResult vkCreateRayTracingPipelinesKHR(VkDevice device, VkDeferredOperationKHR deferredOperation, VkPipelineCache pipelineCache, uint32_t createInfoCount, VkRayTracingPipelineCreateInfoKHR* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
    VkResult vkGetPhysicalDeviceCooperativeMatrixPropertiesNV(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkCooperativeMatrixPropertiesNV* pProperties);
    void vkCmdTraceRaysIndirectKHR(VkCommandBuffer commandBuffer, VkStridedDeviceAddressRegionKHR* pRaygenShaderBindingTable, VkStridedDeviceAddressRegionKHR* pMissShaderBindingTable, VkStridedDeviceAddressRegionKHR* pHitShaderBindingTable, VkStridedDeviceAddressRegionKHR* pCallableShaderBindingTable, VkDeviceAddress indirectDeviceAddress);
    void vkCmdTraceRaysIndirect2KHR(VkCommandBuffer commandBuffer, VkDeviceAddress indirectDeviceAddress);
    void vkGetClusterAccelerationStructureBuildSizesNV(VkDevice device, VkClusterAccelerationStructureInputInfoNV* pInfo, VkAccelerationStructureBuildSizesInfoKHR* pSizeInfo);
    void vkCmdBuildClusterAccelerationStructureIndirectNV(VkCommandBuffer                     commandBuffer, VkClusterAccelerationStructureCommandsInfoNV*  pCommandInfos);
    void vkGetDeviceAccelerationStructureCompatibilityKHR(VkDevice device, VkAccelerationStructureVersionInfoKHR* pVersionInfo, VkAccelerationStructureCompatibilityKHR* pCompatibility);
    VkDeviceSize vkGetRayTracingShaderGroupStackSizeKHR(VkDevice device, VkPipeline pipeline, uint32_t group, VkShaderGroupShaderKHR groupShader);
    void vkCmdSetRayTracingPipelineStackSizeKHR(VkCommandBuffer commandBuffer, uint32_t pipelineStackSize);
    uint32_t vkGetImageViewHandleNVX(VkDevice device, VkImageViewHandleInfoNVX* pInfo);
    uint64_t vkGetImageViewHandle64NVX(VkDevice device, VkImageViewHandleInfoNVX* pInfo);
    VkResult vkGetImageViewAddressNVX(VkDevice device, VkImageView imageView, VkImageViewAddressPropertiesNVX* pProperties);
    uint64_t vkGetDeviceCombinedImageSamplerIndexNVX(VkDevice device, uint64_t imageViewIndex, uint64_t samplerIndex);
    VkResult vkGetPhysicalDeviceSurfacePresentModes2EXT(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, uint32_t* pPresentModeCount, VkPresentModeKHR* pPresentModes);
    VkResult vkGetDeviceGroupSurfacePresentModes2EXT(VkDevice device, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, VkDeviceGroupPresentModeFlagsKHR* pModes);
    VkResult vkAcquireFullScreenExclusiveModeEXT(VkDevice device, VkSwapchainKHR swapchain);
    VkResult vkReleaseFullScreenExclusiveModeEXT(VkDevice device, VkSwapchainKHR swapchain);
    VkResult vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, uint32_t* pCounterCount, VkPerformanceCounterKHR* pCounters, VkPerformanceCounterDescriptionKHR* pCounterDescriptions);
    void vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR(VkPhysicalDevice physicalDevice, VkQueryPoolPerformanceCreateInfoKHR* pPerformanceQueryCreateInfo, uint32_t* pNumPasses);
    VkResult vkAcquireProfilingLockKHR(VkDevice device, VkAcquireProfilingLockInfoKHR* pInfo);
    void vkReleaseProfilingLockKHR(VkDevice device);
    VkResult vkGetImageDrmFormatModifierPropertiesEXT(VkDevice device, VkImage image, VkImageDrmFormatModifierPropertiesEXT* pProperties);
    uint64_t vkGetBufferOpaqueCaptureAddress(VkDevice device, VkBufferDeviceAddressInfo* pInfo);
    VkDeviceAddress vkGetBufferDeviceAddress(VkDevice device, VkBufferDeviceAddressInfo* pInfo);
    VkResult vkCreateHeadlessSurfaceEXT(VkInstance instance, VkHeadlessSurfaceCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
    VkResult vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV(VkPhysicalDevice physicalDevice, uint32_t* pCombinationCount, VkFramebufferMixedSamplesCombinationNV* pCombinations);
    VkResult vkInitializePerformanceApiINTEL(VkDevice device, VkInitializePerformanceApiInfoINTEL* pInitializeInfo);
    void vkUninitializePerformanceApiINTEL(VkDevice device);
    VkResult vkCmdSetPerformanceMarkerINTEL(VkCommandBuffer commandBuffer, VkPerformanceMarkerInfoINTEL* pMarkerInfo);
    VkResult vkCmdSetPerformanceStreamMarkerINTEL(VkCommandBuffer commandBuffer, VkPerformanceStreamMarkerInfoINTEL* pMarkerInfo);
    VkResult vkCmdSetPerformanceOverrideINTEL(VkCommandBuffer commandBuffer, VkPerformanceOverrideInfoINTEL* pOverrideInfo);
    VkResult vkAcquirePerformanceConfigurationINTEL(VkDevice device, VkPerformanceConfigurationAcquireInfoINTEL* pAcquireInfo, VkPerformanceConfigurationINTEL* pConfiguration);
    VkResult vkReleasePerformanceConfigurationINTEL(VkDevice device, VkPerformanceConfigurationINTEL configuration);
    VkResult vkQueueSetPerformanceConfigurationINTEL(VkQueue queue, VkPerformanceConfigurationINTEL configuration);
    VkResult vkGetPerformanceParameterINTEL(VkDevice device, VkPerformanceParameterTypeINTEL parameter, VkPerformanceValueINTEL* pValue);
    uint64_t vkGetDeviceMemoryOpaqueCaptureAddress(VkDevice device, VkDeviceMemoryOpaqueCaptureAddressInfo* pInfo);
    VkResult vkGetPipelineExecutablePropertiesKHR(VkDevice                        device, VkPipelineInfoKHR*        pPipelineInfo, uint32_t* pExecutableCount, VkPipelineExecutablePropertiesKHR* pProperties);
    VkResult vkGetPipelineExecutableStatisticsKHR(VkDevice                        device, VkPipelineExecutableInfoKHR*  pExecutableInfo, uint32_t* pStatisticCount, VkPipelineExecutableStatisticKHR* pStatistics);
    VkResult vkGetPipelineExecutableInternalRepresentationsKHR(VkDevice                        device, VkPipelineExecutableInfoKHR*  pExecutableInfo, uint32_t* pInternalRepresentationCount, VkPipelineExecutableInternalRepresentationKHR* pInternalRepresentations);
    void vkCmdSetLineStipple(VkCommandBuffer commandBuffer, uint32_t lineStippleFactor, uint16_t lineStipplePattern);
    VkResult vkGetFaultData(VkDevice device, VkFaultQueryBehavior faultQueryBehavior, VkBool32* pUnrecordedFaults, uint32_t* pFaultCount, VkFaultData* pFaults);
    VkResult vkGetPhysicalDeviceToolProperties(VkPhysicalDevice physicalDevice, uint32_t* pToolCount, VkPhysicalDeviceToolProperties* pToolProperties);
    VkResult vkCreateAccelerationStructureKHR(VkDevice                                           device, VkAccelerationStructureCreateInfoKHR*        pCreateInfo, VkAllocationCallbacks*       pAllocator, VkAccelerationStructureKHR*                        pAccelerationStructure);
    void vkCmdBuildAccelerationStructuresKHR(VkCommandBuffer                                    commandBuffer, uint32_t infoCount, VkAccelerationStructureBuildGeometryInfoKHR* pInfos, VkAccelerationStructureBuildRangeInfoKHR* const* ppBuildRangeInfos);
    void vkCmdBuildAccelerationStructuresIndirectKHR(VkCommandBuffer                  commandBuffer, uint32_t                                           infoCount, VkAccelerationStructureBuildGeometryInfoKHR* pInfos, VkDeviceAddress*             pIndirectDeviceAddresses, uint32_t*                    pIndirectStrides, uint32_t* const*             ppMaxPrimitiveCounts);
    VkResult vkBuildAccelerationStructuresKHR(VkDevice                                           device, VkDeferredOperationKHR deferredOperation, uint32_t infoCount, VkAccelerationStructureBuildGeometryInfoKHR* pInfos, VkAccelerationStructureBuildRangeInfoKHR* const* ppBuildRangeInfos);
    VkDeviceAddress vkGetAccelerationStructureDeviceAddressKHR(VkDevice device, VkAccelerationStructureDeviceAddressInfoKHR* pInfo);
    VkResult vkCreateDeferredOperationKHR(VkDevice device, VkAllocationCallbacks* pAllocator, VkDeferredOperationKHR* pDeferredOperation);
    void vkDestroyDeferredOperationKHR(VkDevice device, VkDeferredOperationKHR operation, VkAllocationCallbacks* pAllocator);
    uint32_t vkGetDeferredOperationMaxConcurrencyKHR(VkDevice device, VkDeferredOperationKHR operation);
    VkResult vkGetDeferredOperationResultKHR(VkDevice device, VkDeferredOperationKHR operation);
    VkResult vkDeferredOperationJoinKHR(VkDevice device, VkDeferredOperationKHR operation);
    void vkGetPipelineIndirectMemoryRequirementsNV(VkDevice device, VkComputePipelineCreateInfo* pCreateInfo, VkMemoryRequirements2* pMemoryRequirements);
    VkDeviceAddress vkGetPipelineIndirectDeviceAddressNV(VkDevice device, VkPipelineIndirectDeviceAddressInfoNV* pInfo);
    void vkAntiLagUpdateAMD(VkDevice device, VkAntiLagDataAMD* pData);
    void vkCmdSetCullMode(VkCommandBuffer commandBuffer, VkCullModeFlags cullMode);
    void vkCmdSetFrontFace(VkCommandBuffer commandBuffer, VkFrontFace frontFace);
    void vkCmdSetPrimitiveTopology(VkCommandBuffer commandBuffer, VkPrimitiveTopology primitiveTopology);
    void vkCmdSetViewportWithCount(VkCommandBuffer commandBuffer, uint32_t viewportCount, VkViewport* pViewports);
    void vkCmdSetScissorWithCount(VkCommandBuffer commandBuffer, uint32_t scissorCount, VkRect2D* pScissors);
    void vkCmdBindIndexBuffer2(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkDeviceSize size, VkIndexType indexType);
    void vkCmdBindVertexBuffers2(VkCommandBuffer commandBuffer, uint32_t firstBinding, uint32_t bindingCount, VkBuffer* pBuffers, VkDeviceSize* pOffsets, VkDeviceSize* pSizes, VkDeviceSize* pStrides);
    void vkCmdSetDepthTestEnable(VkCommandBuffer commandBuffer, VkBool32 depthTestEnable);
    void vkCmdSetDepthWriteEnable(VkCommandBuffer commandBuffer, VkBool32 depthWriteEnable);
    void vkCmdSetDepthCompareOp(VkCommandBuffer commandBuffer, VkCompareOp depthCompareOp);
    void vkCmdSetDepthBoundsTestEnable(VkCommandBuffer commandBuffer, VkBool32 depthBoundsTestEnable);
    void vkCmdSetStencilTestEnable(VkCommandBuffer commandBuffer, VkBool32 stencilTestEnable);
    void vkCmdSetStencilOp(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, VkStencilOp failOp, VkStencilOp passOp, VkStencilOp depthFailOp, VkCompareOp compareOp);
    void vkCmdSetPatchControlPointsEXT(VkCommandBuffer commandBuffer, uint32_t patchControlPoints);
    void vkCmdSetRasterizerDiscardEnable(VkCommandBuffer commandBuffer, VkBool32 rasterizerDiscardEnable);
    void vkCmdSetDepthBiasEnable(VkCommandBuffer commandBuffer, VkBool32 depthBiasEnable);
    void vkCmdSetLogicOpEXT(VkCommandBuffer commandBuffer, VkLogicOp logicOp);
    void vkCmdSetPrimitiveRestartEnable(VkCommandBuffer commandBuffer, VkBool32 primitiveRestartEnable);
    void vkCmdSetTessellationDomainOriginEXT(VkCommandBuffer commandBuffer, VkTessellationDomainOrigin domainOrigin);
    void vkCmdSetDepthClampEnableEXT(VkCommandBuffer commandBuffer, VkBool32 depthClampEnable);
    void vkCmdSetPolygonModeEXT(VkCommandBuffer commandBuffer, VkPolygonMode polygonMode);
    void vkCmdSetRasterizationSamplesEXT(VkCommandBuffer commandBuffer, VkSampleCountFlagBits  rasterizationSamples);
    void vkCmdSetSampleMaskEXT(VkCommandBuffer commandBuffer, VkSampleCountFlagBits  samples, VkSampleMask*    pSampleMask);
    void vkCmdSetAlphaToCoverageEnableEXT(VkCommandBuffer commandBuffer, VkBool32 alphaToCoverageEnable);
    void vkCmdSetAlphaToOneEnableEXT(VkCommandBuffer commandBuffer, VkBool32 alphaToOneEnable);
    void vkCmdSetLogicOpEnableEXT(VkCommandBuffer commandBuffer, VkBool32 logicOpEnable);
    void vkCmdSetColorBlendEnableEXT(VkCommandBuffer commandBuffer, uint32_t firstAttachment, uint32_t attachmentCount, VkBool32* pColorBlendEnables);
    void vkCmdSetColorBlendEquationEXT(VkCommandBuffer commandBuffer, uint32_t firstAttachment, uint32_t attachmentCount, VkColorBlendEquationEXT* pColorBlendEquations);
    void vkCmdSetColorWriteMaskEXT(VkCommandBuffer commandBuffer, uint32_t firstAttachment, uint32_t attachmentCount, VkColorComponentFlags* pColorWriteMasks);
    void vkCmdSetRasterizationStreamEXT(VkCommandBuffer commandBuffer, uint32_t rasterizationStream);
    void vkCmdSetConservativeRasterizationModeEXT(VkCommandBuffer commandBuffer, VkConservativeRasterizationModeEXT conservativeRasterizationMode);
    void vkCmdSetExtraPrimitiveOverestimationSizeEXT(VkCommandBuffer commandBuffer, float extraPrimitiveOverestimationSize);
    void vkCmdSetDepthClipEnableEXT(VkCommandBuffer commandBuffer, VkBool32 depthClipEnable);
    void vkCmdSetSampleLocationsEnableEXT(VkCommandBuffer commandBuffer, VkBool32 sampleLocationsEnable);
    void vkCmdSetColorBlendAdvancedEXT(VkCommandBuffer commandBuffer, uint32_t firstAttachment, uint32_t attachmentCount, VkColorBlendAdvancedEXT* pColorBlendAdvanced);
    void vkCmdSetProvokingVertexModeEXT(VkCommandBuffer commandBuffer, VkProvokingVertexModeEXT provokingVertexMode);
    void vkCmdSetLineRasterizationModeEXT(VkCommandBuffer commandBuffer, VkLineRasterizationModeEXT lineRasterizationMode);
    void vkCmdSetLineStippleEnableEXT(VkCommandBuffer commandBuffer, VkBool32 stippledLineEnable);
    void vkCmdSetDepthClipNegativeOneToOneEXT(VkCommandBuffer commandBuffer, VkBool32 negativeOneToOne);
    void vkCmdSetViewportWScalingEnableNV(VkCommandBuffer commandBuffer, VkBool32 viewportWScalingEnable);
    void vkCmdSetViewportSwizzleNV(VkCommandBuffer commandBuffer, uint32_t firstViewport, uint32_t viewportCount, VkViewportSwizzleNV* pViewportSwizzles);
    void vkCmdSetCoverageToColorEnableNV(VkCommandBuffer commandBuffer, VkBool32 coverageToColorEnable);
    void vkCmdSetCoverageToColorLocationNV(VkCommandBuffer commandBuffer, uint32_t coverageToColorLocation);
    void vkCmdSetCoverageModulationModeNV(VkCommandBuffer commandBuffer, VkCoverageModulationModeNV coverageModulationMode);
    void vkCmdSetCoverageModulationTableEnableNV(VkCommandBuffer commandBuffer, VkBool32 coverageModulationTableEnable);
    void vkCmdSetCoverageModulationTableNV(VkCommandBuffer commandBuffer, uint32_t coverageModulationTableCount, float* pCoverageModulationTable);
    void vkCmdSetShadingRateImageEnableNV(VkCommandBuffer commandBuffer, VkBool32 shadingRateImageEnable);
    void vkCmdSetCoverageReductionModeNV(VkCommandBuffer commandBuffer, VkCoverageReductionModeNV coverageReductionMode);
    void vkCmdSetRepresentativeFragmentTestEnableNV(VkCommandBuffer commandBuffer, VkBool32 representativeFragmentTestEnable);
    VkResult vkCreatePrivateDataSlot(VkDevice device, VkPrivateDataSlotCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPrivateDataSlot* pPrivateDataSlot);
    void vkDestroyPrivateDataSlot(VkDevice device, VkPrivateDataSlot privateDataSlot, VkAllocationCallbacks* pAllocator);
    VkResult vkSetPrivateData(VkDevice device, VkObjectType objectType, uint64_t objectHandle, VkPrivateDataSlot privateDataSlot, uint64_t data);
    void vkGetPrivateData(VkDevice device, VkObjectType objectType, uint64_t objectHandle, VkPrivateDataSlot privateDataSlot, uint64_t* pData);
    void vkCmdCopyBuffer2(VkCommandBuffer commandBuffer, VkCopyBufferInfo2* pCopyBufferInfo);
    void vkCmdCopyImage2(VkCommandBuffer commandBuffer, VkCopyImageInfo2* pCopyImageInfo);
    void vkCmdBlitImage2(VkCommandBuffer commandBuffer, VkBlitImageInfo2* pBlitImageInfo);
    void vkCmdCopyBufferToImage2(VkCommandBuffer commandBuffer, VkCopyBufferToImageInfo2* pCopyBufferToImageInfo);
    void vkCmdCopyImageToBuffer2(VkCommandBuffer commandBuffer, VkCopyImageToBufferInfo2* pCopyImageToBufferInfo);
    void vkCmdResolveImage2(VkCommandBuffer commandBuffer, VkResolveImageInfo2* pResolveImageInfo);
    void vkCmdRefreshObjectsKHR(VkCommandBuffer commandBuffer, VkRefreshObjectListKHR* pRefreshObjects);
    VkResult vkGetPhysicalDeviceRefreshableObjectTypesKHR(VkPhysicalDevice physicalDevice, uint32_t* pRefreshableObjectTypeCount, VkObjectType* pRefreshableObjectTypes);
    void vkCmdSetFragmentShadingRateKHR(VkCommandBuffer           commandBuffer, VkExtent2D*                           pFragmentSize, VkFragmentShadingRateCombinerOpKHR    combinerOps[2]);
    VkResult vkGetPhysicalDeviceFragmentShadingRatesKHR(VkPhysicalDevice physicalDevice, uint32_t* pFragmentShadingRateCount, VkPhysicalDeviceFragmentShadingRateKHR* pFragmentShadingRates);
    void vkCmdSetFragmentShadingRateEnumNV(VkCommandBuffer           commandBuffer, VkFragmentShadingRateNV                     shadingRate, VkFragmentShadingRateCombinerOpKHR    combinerOps[2]);
    void vkGetAccelerationStructureBuildSizesKHR(VkDevice                                            device, VkAccelerationStructureBuildTypeKHR                 buildType, VkAccelerationStructureBuildGeometryInfoKHR*  pBuildInfo, uint32_t*  pMaxPrimitiveCounts, VkAccelerationStructureBuildSizesInfoKHR*           pSizeInfo);
    void vkCmdSetVertexInputEXT(VkCommandBuffer commandBuffer, uint32_t vertexBindingDescriptionCount, VkVertexInputBindingDescription2EXT* pVertexBindingDescriptions, uint32_t vertexAttributeDescriptionCount, VkVertexInputAttributeDescription2EXT* pVertexAttributeDescriptions);
    void vkCmdSetColorWriteEnableEXT(VkCommandBuffer       commandBuffer, uint32_t                                attachmentCount, VkBool32*   pColorWriteEnables);
    void vkCmdSetEvent2(VkCommandBuffer                   commandBuffer, VkEvent                                             event, VkDependencyInfo*                             pDependencyInfo);
    void vkCmdResetEvent2(VkCommandBuffer                   commandBuffer, VkEvent                                             event, VkPipelineStageFlags2               stageMask);
    void vkCmdWaitEvents2(VkCommandBuffer                   commandBuffer, uint32_t                                            eventCount, VkEvent*                     pEvents, VkDependencyInfo*            pDependencyInfos);
    void vkCmdPipelineBarrier2(VkCommandBuffer                   commandBuffer, VkDependencyInfo*                             pDependencyInfo);
    VkResult vkQueueSubmit2(VkQueue                          queue, uint32_t                            submitCount, VkSubmitInfo2*              pSubmits, VkFence           fence);
    void vkCmdWriteTimestamp2(VkCommandBuffer                   commandBuffer, VkPipelineStageFlags2               stage, VkQueryPool                                         queryPool, uint32_t                                            query);
    void vkCmdWriteBufferMarker2AMD(VkCommandBuffer                   commandBuffer, VkPipelineStageFlags2               stage, VkBuffer                                            dstBuffer, VkDeviceSize                                        dstOffset, uint32_t                                            marker);
    void vkGetQueueCheckpointData2NV(VkQueue queue, uint32_t* pCheckpointDataCount, VkCheckpointData2NV* pCheckpointData);
    VkResult vkCopyMemoryToImage(VkDevice device, VkCopyMemoryToImageInfo*    pCopyMemoryToImageInfo);
    VkResult vkCopyImageToMemory(VkDevice device, VkCopyImageToMemoryInfo*    pCopyImageToMemoryInfo);
    VkResult vkCopyImageToImage(VkDevice device, VkCopyImageToImageInfo*    pCopyImageToImageInfo);
    VkResult vkTransitionImageLayout(VkDevice device, uint32_t transitionCount, VkHostImageLayoutTransitionInfo*    pTransitions);
    void vkGetCommandPoolMemoryConsumption(VkDevice device, VkCommandPool commandPool, VkCommandBuffer commandBuffer, VkCommandPoolMemoryConsumption* pConsumption);
    VkResult vkGetPhysicalDeviceVideoCapabilitiesKHR(VkPhysicalDevice physicalDevice, VkVideoProfileInfoKHR* pVideoProfile, VkVideoCapabilitiesKHR* pCapabilities);
    VkResult vkGetPhysicalDeviceVideoFormatPropertiesKHR(VkPhysicalDevice physicalDevice, VkPhysicalDeviceVideoFormatInfoKHR* pVideoFormatInfo, uint32_t* pVideoFormatPropertyCount, VkVideoFormatPropertiesKHR* pVideoFormatProperties);
    VkResult vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR(VkPhysicalDevice physicalDevice, VkPhysicalDeviceVideoEncodeQualityLevelInfoKHR* pQualityLevelInfo, VkVideoEncodeQualityLevelPropertiesKHR* pQualityLevelProperties);
    VkResult vkCreateVideoSessionKHR(VkDevice device, VkVideoSessionCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkVideoSessionKHR* pVideoSession);
    void vkDestroyVideoSessionKHR(VkDevice device, VkVideoSessionKHR videoSession, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateVideoSessionParametersKHR(VkDevice device, VkVideoSessionParametersCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkVideoSessionParametersKHR* pVideoSessionParameters);
    VkResult vkUpdateVideoSessionParametersKHR(VkDevice device, VkVideoSessionParametersKHR videoSessionParameters, VkVideoSessionParametersUpdateInfoKHR* pUpdateInfo);
    VkResult vkGetEncodedVideoSessionParametersKHR(VkDevice device, VkVideoEncodeSessionParametersGetInfoKHR* pVideoSessionParametersInfo, VkVideoEncodeSessionParametersFeedbackInfoKHR* pFeedbackInfo, size_t* pDataSize, void* pData);
    void vkDestroyVideoSessionParametersKHR(VkDevice device, VkVideoSessionParametersKHR videoSessionParameters, VkAllocationCallbacks* pAllocator);
    VkResult vkGetVideoSessionMemoryRequirementsKHR(VkDevice device, VkVideoSessionKHR videoSession, uint32_t* pMemoryRequirementsCount, VkVideoSessionMemoryRequirementsKHR* pMemoryRequirements);
    VkResult vkBindVideoSessionMemoryKHR(VkDevice device, VkVideoSessionKHR videoSession, uint32_t bindSessionMemoryInfoCount, VkBindVideoSessionMemoryInfoKHR* pBindSessionMemoryInfos);
    void vkCmdDecodeVideoKHR(VkCommandBuffer commandBuffer, VkVideoDecodeInfoKHR* pDecodeInfo);
    void vkCmdBeginVideoCodingKHR(VkCommandBuffer commandBuffer, VkVideoBeginCodingInfoKHR* pBeginInfo);
    void vkCmdControlVideoCodingKHR(VkCommandBuffer commandBuffer, VkVideoCodingControlInfoKHR* pCodingControlInfo);
    void vkCmdEndVideoCodingKHR(VkCommandBuffer commandBuffer, VkVideoEndCodingInfoKHR* pEndCodingInfo);
    void vkCmdEncodeVideoKHR(VkCommandBuffer commandBuffer, VkVideoEncodeInfoKHR* pEncodeInfo);
    void vkCmdDecompressMemoryNV(VkCommandBuffer commandBuffer, uint32_t decompressRegionCount, VkDecompressMemoryRegionNV* pDecompressMemoryRegions);
    void vkCmdDecompressMemoryIndirectCountNV(VkCommandBuffer commandBuffer, VkDeviceAddress indirectCommandsAddress, VkDeviceAddress indirectCommandsCountAddress, uint32_t stride);
    void vkGetPartitionedAccelerationStructuresBuildSizesNV(VkDevice device, VkPartitionedAccelerationStructureInstancesInputNV* pInfo, VkAccelerationStructureBuildSizesInfoKHR*                  pSizeInfo);
    void vkCmdBuildPartitionedAccelerationStructuresNV(VkCommandBuffer                     commandBuffer, VkBuildPartitionedAccelerationStructureInfoNV*  pBuildInfo);
    void vkCmdDecompressMemoryEXT(VkCommandBuffer commandBuffer, VkDecompressMemoryInfoEXT* pDecompressMemoryInfoEXT);
    void vkCmdDecompressMemoryIndirectCountEXT(VkCommandBuffer commandBuffer, VkMemoryDecompressionMethodFlagsEXT decompressionMethod, VkDeviceAddress indirectCommandsAddress, VkDeviceAddress indirectCommandsCountAddress, uint32_t maxDecompressionCount, uint32_t stride);
    VkResult vkCreateCuModuleNVX(VkDevice device, VkCuModuleCreateInfoNVX* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCuModuleNVX* pModule);
    VkResult vkCreateCuFunctionNVX(VkDevice device, VkCuFunctionCreateInfoNVX* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCuFunctionNVX* pFunction);
    void vkDestroyCuModuleNVX(VkDevice device, VkCuModuleNVX module, VkAllocationCallbacks* pAllocator);
    void vkDestroyCuFunctionNVX(VkDevice device, VkCuFunctionNVX function, VkAllocationCallbacks* pAllocator);
    void vkCmdCuLaunchKernelNVX(VkCommandBuffer commandBuffer, VkCuLaunchInfoNVX* pLaunchInfo);
    void vkGetDescriptorSetLayoutSizeEXT(VkDevice device, VkDescriptorSetLayout layout, VkDeviceSize* pLayoutSizeInBytes);
    void vkGetDescriptorSetLayoutBindingOffsetEXT(VkDevice device, VkDescriptorSetLayout layout, uint32_t binding, VkDeviceSize* pOffset);
    void vkGetDescriptorEXT(VkDevice device, VkDescriptorGetInfoEXT* pDescriptorInfo, size_t dataSize, void* pDescriptor);
    void vkCmdBindDescriptorBuffersEXT(VkCommandBuffer commandBuffer, uint32_t bufferCount, VkDescriptorBufferBindingInfoEXT* pBindingInfos);
    void vkCmdSetDescriptorBufferOffsetsEXT(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t firstSet, uint32_t setCount, uint32_t* pBufferIndices, VkDeviceSize* pOffsets);
    void vkCmdBindDescriptorBufferEmbeddedSamplersEXT(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t set);
    VkResult vkGetBufferOpaqueCaptureDescriptorDataEXT(VkDevice device, VkBufferCaptureDescriptorDataInfoEXT* pInfo, void* pData);
    VkResult vkGetImageOpaqueCaptureDescriptorDataEXT(VkDevice device, VkImageCaptureDescriptorDataInfoEXT* pInfo, void* pData);
    VkResult vkGetImageViewOpaqueCaptureDescriptorDataEXT(VkDevice device, VkImageViewCaptureDescriptorDataInfoEXT* pInfo, void* pData);
    VkResult vkGetSamplerOpaqueCaptureDescriptorDataEXT(VkDevice device, VkSamplerCaptureDescriptorDataInfoEXT* pInfo, void* pData);
    VkResult vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT(VkDevice device, VkAccelerationStructureCaptureDescriptorDataInfoEXT* pInfo, void* pData);
    void vkSetDeviceMemoryPriorityEXT(VkDevice       device, VkDeviceMemory memory, float          priority);
    VkResult vkAcquireDrmDisplayEXT(VkPhysicalDevice physicalDevice, int32_t drmFd, VkDisplayKHR display);
    VkResult vkGetDrmDisplayEXT(VkPhysicalDevice physicalDevice, int32_t drmFd, uint32_t connectorId, VkDisplayKHR* display);
    VkResult vkWaitForPresent2KHR(VkDevice device, VkSwapchainKHR swapchain, VkPresentWait2InfoKHR* pPresentWait2Info);
    VkResult vkWaitForPresentKHR(VkDevice device, VkSwapchainKHR swapchain, uint64_t presentId, uint64_t timeout);
    VkResult vkCreateBufferCollectionFUCHSIA(VkDevice device, VkBufferCollectionCreateInfoFUCHSIA* pCreateInfo, VkAllocationCallbacks* pAllocator, VkBufferCollectionFUCHSIA* pCollection);
    VkResult vkSetBufferCollectionBufferConstraintsFUCHSIA(VkDevice device, VkBufferCollectionFUCHSIA collection, VkBufferConstraintsInfoFUCHSIA* pBufferConstraintsInfo);
    VkResult vkSetBufferCollectionImageConstraintsFUCHSIA(VkDevice device, VkBufferCollectionFUCHSIA collection, VkImageConstraintsInfoFUCHSIA* pImageConstraintsInfo);
    void vkDestroyBufferCollectionFUCHSIA(VkDevice device, VkBufferCollectionFUCHSIA collection, VkAllocationCallbacks* pAllocator);
    VkResult vkGetBufferCollectionPropertiesFUCHSIA(VkDevice device, VkBufferCollectionFUCHSIA collection, VkBufferCollectionPropertiesFUCHSIA* pProperties);
    VkResult vkCreateCudaModuleNV(VkDevice device, VkCudaModuleCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCudaModuleNV* pModule);
    VkResult vkGetCudaModuleCacheNV(VkDevice device, VkCudaModuleNV module, size_t* pCacheSize, void* pCacheData);
    VkResult vkCreateCudaFunctionNV(VkDevice device, VkCudaFunctionCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCudaFunctionNV* pFunction);
    void vkDestroyCudaModuleNV(VkDevice device, VkCudaModuleNV module, VkAllocationCallbacks* pAllocator);
    void vkDestroyCudaFunctionNV(VkDevice device, VkCudaFunctionNV function, VkAllocationCallbacks* pAllocator);
    void vkCmdCudaLaunchKernelNV(VkCommandBuffer commandBuffer, VkCudaLaunchInfoNV* pLaunchInfo);
    void vkCmdBeginRendering(VkCommandBuffer                   commandBuffer, VkRenderingInfo*                              pRenderingInfo);
    void vkCmdEndRendering(VkCommandBuffer                   commandBuffer);
    void vkCmdEndRendering2KHR(VkCommandBuffer                   commandBuffer, VkRenderingEndInfoKHR*        pRenderingEndInfo);
    void vkGetDescriptorSetLayoutHostMappingInfoVALVE(VkDevice device, VkDescriptorSetBindingReferenceVALVE* pBindingReference, VkDescriptorSetLayoutHostMappingInfoVALVE* pHostMapping);
    void vkGetDescriptorSetHostMappingVALVE(VkDevice device, VkDescriptorSet descriptorSet, void** ppData);
    VkResult vkCreateMicromapEXT(VkDevice                                           device, VkMicromapCreateInfoEXT*        pCreateInfo, VkAllocationCallbacks*       pAllocator, VkMicromapEXT*                        pMicromap);
    void vkCmdBuildMicromapsEXT(VkCommandBuffer                                    commandBuffer, uint32_t infoCount, VkMicromapBuildInfoEXT* pInfos);
    VkResult vkBuildMicromapsEXT(VkDevice                                           device, VkDeferredOperationKHR deferredOperation, uint32_t infoCount, VkMicromapBuildInfoEXT* pInfos);
    void vkDestroyMicromapEXT(VkDevice device, VkMicromapEXT micromap, VkAllocationCallbacks* pAllocator);
    void vkCmdCopyMicromapEXT(VkCommandBuffer commandBuffer, VkCopyMicromapInfoEXT* pInfo);
    VkResult vkCopyMicromapEXT(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMicromapInfoEXT* pInfo);
    void vkCmdCopyMicromapToMemoryEXT(VkCommandBuffer commandBuffer, VkCopyMicromapToMemoryInfoEXT* pInfo);
    VkResult vkCopyMicromapToMemoryEXT(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMicromapToMemoryInfoEXT* pInfo);
    void vkCmdCopyMemoryToMicromapEXT(VkCommandBuffer commandBuffer, VkCopyMemoryToMicromapInfoEXT* pInfo);
    VkResult vkCopyMemoryToMicromapEXT(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMemoryToMicromapInfoEXT* pInfo);
    void vkCmdWriteMicromapsPropertiesEXT(VkCommandBuffer commandBuffer, uint32_t micromapCount, VkMicromapEXT* pMicromaps, VkQueryType queryType, VkQueryPool queryPool, uint32_t firstQuery);
    VkResult vkWriteMicromapsPropertiesEXT(VkDevice device, uint32_t micromapCount, VkMicromapEXT* pMicromaps, VkQueryType  queryType, size_t       dataSize, void* pData, size_t stride);
    void vkGetDeviceMicromapCompatibilityEXT(VkDevice device, VkMicromapVersionInfoEXT* pVersionInfo, VkAccelerationStructureCompatibilityKHR* pCompatibility);
    void vkGetMicromapBuildSizesEXT(VkDevice                                            device, VkAccelerationStructureBuildTypeKHR                 buildType, VkMicromapBuildInfoEXT*  pBuildInfo, VkMicromapBuildSizesInfoEXT*           pSizeInfo);
    void vkGetShaderModuleIdentifierEXT(VkDevice device, VkShaderModule shaderModule, VkShaderModuleIdentifierEXT* pIdentifier);
    void vkGetShaderModuleCreateInfoIdentifierEXT(VkDevice device, VkShaderModuleCreateInfo* pCreateInfo, VkShaderModuleIdentifierEXT* pIdentifier);
    void vkGetImageSubresourceLayout2(VkDevice device, VkImage image, VkImageSubresource2* pSubresource, VkSubresourceLayout2* pLayout);
    VkResult vkGetPipelinePropertiesEXT(VkDevice device, VkPipelineInfoEXT* pPipelineInfo, VkBaseOutStructure* pPipelineProperties);
    void vkExportMetalObjectsEXT(VkDevice device, VkExportMetalObjectsInfoEXT* pMetalObjectsInfo);
    void vkCmdBindTileMemoryQCOM(VkCommandBuffer commandBuffer, VkTileMemoryBindInfoQCOM* pTileMemoryBindInfo);
    VkResult vkGetFramebufferTilePropertiesQCOM(VkDevice device, VkFramebuffer framebuffer, uint32_t* pPropertiesCount, VkTilePropertiesQCOM* pProperties);
    VkResult vkGetDynamicRenderingTilePropertiesQCOM(VkDevice device, VkRenderingInfo* pRenderingInfo, VkTilePropertiesQCOM* pProperties);
    VkResult vkGetPhysicalDeviceOpticalFlowImageFormatsNV(VkPhysicalDevice physicalDevice, VkOpticalFlowImageFormatInfoNV* pOpticalFlowImageFormatInfo, uint32_t* pFormatCount, VkOpticalFlowImageFormatPropertiesNV* pImageFormatProperties);
    VkResult vkCreateOpticalFlowSessionNV(VkDevice device, VkOpticalFlowSessionCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkOpticalFlowSessionNV* pSession);
    void vkDestroyOpticalFlowSessionNV(VkDevice device, VkOpticalFlowSessionNV session, VkAllocationCallbacks* pAllocator);
    VkResult vkBindOpticalFlowSessionImageNV(VkDevice device, VkOpticalFlowSessionNV session, VkOpticalFlowSessionBindingPointNV bindingPoint, VkImageView view, VkImageLayout layout);
    void vkCmdOpticalFlowExecuteNV(VkCommandBuffer commandBuffer, VkOpticalFlowSessionNV session, VkOpticalFlowExecuteInfoNV* pExecuteInfo);
    VkResult vkGetDeviceFaultInfoEXT(VkDevice device, VkDeviceFaultCountsEXT* pFaultCounts, VkDeviceFaultInfoEXT* pFaultInfo);
    void vkCmdSetDepthBias2EXT(VkCommandBuffer commandBuffer, VkDepthBiasInfoEXT*         pDepthBiasInfo);
    VkResult vkReleaseSwapchainImagesKHR(VkDevice device, VkReleaseSwapchainImagesInfoKHR* pReleaseInfo);
    void vkGetDeviceImageSubresourceLayout(VkDevice device, VkDeviceImageSubresourceInfo* pInfo, VkSubresourceLayout2* pLayout);
    VkResult vkMapMemory2(VkDevice device, VkMemoryMapInfo* pMemoryMapInfo, void** ppData);
    VkResult vkUnmapMemory2(VkDevice device, VkMemoryUnmapInfo* pMemoryUnmapInfo);
    VkResult vkCreateShadersEXT(VkDevice device, uint32_t createInfoCount, VkShaderCreateInfoEXT* pCreateInfos, VkAllocationCallbacks* pAllocator, VkShaderEXT* pShaders);
    void vkDestroyShaderEXT(VkDevice device, VkShaderEXT shader, VkAllocationCallbacks* pAllocator);
    VkResult vkGetShaderBinaryDataEXT(VkDevice device, VkShaderEXT shader, size_t* pDataSize, void* pData);
    void vkCmdBindShadersEXT(VkCommandBuffer commandBuffer, uint32_t stageCount, VkShaderStageFlagBits* pStages, VkShaderEXT* pShaders);
    VkResult vkSetSwapchainPresentTimingQueueSizeEXT(VkDevice device, VkSwapchainKHR swapchain, uint32_t size);
    VkResult vkGetSwapchainTimingPropertiesEXT(VkDevice device, VkSwapchainKHR swapchain, VkSwapchainTimingPropertiesEXT* pSwapchainTimingProperties, uint64_t* pSwapchainTimingPropertiesCounter);
    VkResult vkGetSwapchainTimeDomainPropertiesEXT(VkDevice device, VkSwapchainKHR swapchain, VkSwapchainTimeDomainPropertiesEXT* pSwapchainTimeDomainProperties, uint64_t* pTimeDomainsCounter);
    VkResult vkGetPastPresentationTimingEXT(VkDevice device, VkPastPresentationTimingInfoEXT* pPastPresentationTimingInfo, VkPastPresentationTimingPropertiesEXT* pPastPresentationTimingProperties);
    VkResult vkGetScreenBufferPropertiesQNX(VkDevice device, struct _screen_buffer* buffer, VkScreenBufferPropertiesQNX* pProperties);
    VkResult vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkCooperativeMatrixPropertiesKHR* pProperties);
    VkResult vkGetExecutionGraphPipelineScratchSizeAMDX(VkDevice                                        device, VkPipeline                                      executionGraph, VkExecutionGraphPipelineScratchSizeAMDX*        pSizeInfo);
    VkResult vkGetExecutionGraphPipelineNodeIndexAMDX(VkDevice                                        device, VkPipeline                                      executionGraph, VkPipelineShaderStageNodeCreateInfoAMDX*  pNodeInfo, uint32_t*                                       pNodeIndex);
    VkResult vkCreateExecutionGraphPipelinesAMDX(VkDevice                                        device, VkPipelineCache pipelineCache, uint32_t                                        createInfoCount, VkExecutionGraphPipelineCreateInfoAMDX* pCreateInfos, VkAllocationCallbacks*    pAllocator, VkPipeline*               pPipelines);
    void vkCmdInitializeGraphScratchMemoryAMDX(VkCommandBuffer                                 commandBuffer, VkPipeline                                      executionGraph, VkDeviceAddress                                 scratch, VkDeviceSize                                    scratchSize);
    void vkCmdDispatchGraphAMDX(VkCommandBuffer                                 commandBuffer, VkDeviceAddress                                 scratch, VkDeviceSize                                    scratchSize, VkDispatchGraphCountInfoAMDX*             pCountInfo);
    void vkCmdDispatchGraphIndirectAMDX(VkCommandBuffer                                 commandBuffer, VkDeviceAddress                                 scratch, VkDeviceSize                                    scratchSize, VkDispatchGraphCountInfoAMDX*             pCountInfo);
    void vkCmdDispatchGraphIndirectCountAMDX(VkCommandBuffer                                 commandBuffer, VkDeviceAddress                                 scratch, VkDeviceSize                                    scratchSize, VkDeviceAddress                                 countInfo);
    void vkCmdBindDescriptorSets2(VkCommandBuffer commandBuffer, VkBindDescriptorSetsInfo*   pBindDescriptorSetsInfo);
    void vkCmdPushConstants2(VkCommandBuffer commandBuffer, VkPushConstantsInfo*        pPushConstantsInfo);
    void vkCmdPushDescriptorSet2(VkCommandBuffer commandBuffer, VkPushDescriptorSetInfo*    pPushDescriptorSetInfo);
    void vkCmdPushDescriptorSetWithTemplate2(VkCommandBuffer commandBuffer, VkPushDescriptorSetWithTemplateInfo* pPushDescriptorSetWithTemplateInfo);
    void vkCmdSetDescriptorBufferOffsets2EXT(VkCommandBuffer commandBuffer, VkSetDescriptorBufferOffsetsInfoEXT* pSetDescriptorBufferOffsetsInfo);
    void vkCmdBindDescriptorBufferEmbeddedSamplers2EXT(VkCommandBuffer commandBuffer, VkBindDescriptorBufferEmbeddedSamplersInfoEXT* pBindDescriptorBufferEmbeddedSamplersInfo);
    VkResult vkSetLatencySleepModeNV(VkDevice device, VkSwapchainKHR swapchain, VkLatencySleepModeInfoNV* pSleepModeInfo);
    VkResult vkLatencySleepNV(VkDevice device, VkSwapchainKHR swapchain, VkLatencySleepInfoNV* pSleepInfo);
    void vkSetLatencyMarkerNV(VkDevice device, VkSwapchainKHR swapchain, VkSetLatencyMarkerInfoNV* pLatencyMarkerInfo);
    void vkGetLatencyTimingsNV(VkDevice device, VkSwapchainKHR swapchain, VkGetLatencyMarkerInfoNV* pLatencyMarkerInfo);
    void vkQueueNotifyOutOfBandNV(VkQueue queue, VkOutOfBandQueueTypeInfoNV* pQueueTypeInfo);
    void vkCmdSetRenderingAttachmentLocations(VkCommandBuffer commandBuffer, VkRenderingAttachmentLocationInfo* pLocationInfo);
    void vkCmdSetRenderingInputAttachmentIndices(VkCommandBuffer commandBuffer, VkRenderingInputAttachmentIndexInfo* pInputAttachmentIndexInfo);
    void vkCmdSetDepthClampRangeEXT(VkCommandBuffer commandBuffer, VkDepthClampModeEXT depthClampMode, VkDepthClampRangeEXT* pDepthClampRange);
    VkResult vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkCooperativeMatrixFlexibleDimensionsPropertiesNV* pProperties);
    VkResult vkGetMemoryMetalHandleEXT(VkDevice device, VkMemoryGetMetalHandleInfoEXT* pGetMetalHandleInfo, void** pHandle);
    VkResult vkGetMemoryMetalHandlePropertiesEXT(VkDevice device, VkExternalMemoryHandleTypeFlagBits handleType, void* pHandle, VkMemoryMetalHandlePropertiesEXT* pMemoryMetalHandleProperties);
    VkResult vkGetPhysicalDeviceCooperativeVectorPropertiesNV(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkCooperativeVectorPropertiesNV* pProperties);
    VkResult vkConvertCooperativeVectorMatrixNV(VkDevice device, VkConvertCooperativeVectorMatrixInfoNV* pInfo);
    void vkCmdConvertCooperativeVectorMatrixNV(VkCommandBuffer commandBuffer, uint32_t infoCount, VkConvertCooperativeVectorMatrixInfoNV* pInfos);
    void vkCmdDispatchTileQCOM(VkCommandBuffer commandBuffer, VkDispatchTileInfoQCOM* pDispatchTileInfo);
    void vkCmdBeginPerTileExecutionQCOM(VkCommandBuffer commandBuffer, VkPerTileBeginInfoQCOM* pPerTileBeginInfo);
    void vkCmdEndPerTileExecutionQCOM(VkCommandBuffer commandBuffer, VkPerTileEndInfoQCOM* pPerTileEndInfo);
    VkResult vkCreateExternalComputeQueueNV(VkDevice device, VkExternalComputeQueueCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkExternalComputeQueueNV* pExternalQueue);
    void vkDestroyExternalComputeQueueNV(VkDevice device, VkExternalComputeQueueNV externalQueue, VkAllocationCallbacks* pAllocator);
    void vkGetExternalComputeQueueDataNV(VkExternalComputeQueueNV externalQueue, VkExternalComputeQueueDataParamsNV* params, void* pData);
    VkResult vkCreateTensorARM(VkDevice device, VkTensorCreateInfoARM* pCreateInfo, VkAllocationCallbacks* pAllocator, VkTensorARM* pTensor);
    void vkDestroyTensorARM(VkDevice device, VkTensorARM tensor, VkAllocationCallbacks* pAllocator);
    VkResult vkCreateTensorViewARM(VkDevice device, VkTensorViewCreateInfoARM* pCreateInfo, VkAllocationCallbacks* pAllocator, VkTensorViewARM* pView);
    void vkDestroyTensorViewARM(VkDevice device, VkTensorViewARM tensorView, VkAllocationCallbacks* pAllocator);
    void vkGetTensorMemoryRequirementsARM(VkDevice device, VkTensorMemoryRequirementsInfoARM* pInfo, VkMemoryRequirements2* pMemoryRequirements);
    VkResult vkBindTensorMemoryARM(VkDevice device, uint32_t bindInfoCount, VkBindTensorMemoryInfoARM* pBindInfos);
    void vkGetDeviceTensorMemoryRequirementsARM(VkDevice device, VkDeviceTensorMemoryRequirementsARM* pInfo, VkMemoryRequirements2* pMemoryRequirements);
    void vkCmdCopyTensorARM(VkCommandBuffer commandBuffer, VkCopyTensorInfoARM* pCopyTensorInfo);
    VkResult vkGetTensorOpaqueCaptureDescriptorDataARM(VkDevice                                    device, VkTensorCaptureDescriptorDataInfoARM* pInfo, void*                                       pData);
    VkResult vkGetTensorViewOpaqueCaptureDescriptorDataARM(VkDevice                                        device, VkTensorViewCaptureDescriptorDataInfoARM* pInfo, void*                                           pData);
    void vkGetPhysicalDeviceExternalTensorPropertiesARM(VkPhysicalDevice                             physicalDevice, VkPhysicalDeviceExternalTensorInfoARM* pExternalTensorInfo, VkExternalTensorPropertiesARM*               pExternalTensorProperties);
    VkResult vkCreateDataGraphPipelinesARM(VkDevice               device, VkDeferredOperationKHR deferredOperation, VkPipelineCache        pipelineCache, uint32_t               createInfoCount, VkDataGraphPipelineCreateInfoARM* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline*     pPipelines);
    VkResult vkCreateDataGraphPipelineSessionARM(VkDevice                                     device, VkDataGraphPipelineSessionCreateInfoARM*   pCreateInfo, VkAllocationCallbacks* pAllocator, VkDataGraphPipelineSessionARM*                   pSession);
    VkResult vkGetDataGraphPipelineSessionBindPointRequirementsARM(VkDevice device, VkDataGraphPipelineSessionBindPointRequirementsInfoARM* pInfo, uint32_t* pBindPointRequirementCount, VkDataGraphPipelineSessionBindPointRequirementARM* pBindPointRequirements);
    void vkGetDataGraphPipelineSessionMemoryRequirementsARM(VkDevice device, VkDataGraphPipelineSessionMemoryRequirementsInfoARM* pInfo, VkMemoryRequirements2* pMemoryRequirements);
    VkResult vkBindDataGraphPipelineSessionMemoryARM(VkDevice device, uint32_t bindInfoCount, VkBindDataGraphPipelineSessionMemoryInfoARM* pBindInfos);
    void vkDestroyDataGraphPipelineSessionARM(VkDevice device, VkDataGraphPipelineSessionARM session, VkAllocationCallbacks* pAllocator);
    void vkCmdDispatchDataGraphARM(VkCommandBuffer commandBuffer, VkDataGraphPipelineSessionARM session, VkDataGraphPipelineDispatchInfoARM* pInfo);
    VkResult vkGetDataGraphPipelineAvailablePropertiesARM(VkDevice device, VkDataGraphPipelineInfoARM* pPipelineInfo, uint32_t* pPropertiesCount, VkDataGraphPipelinePropertyARM* pProperties);
    VkResult vkGetDataGraphPipelinePropertiesARM(VkDevice                          device, VkDataGraphPipelineInfoARM* pPipelineInfo, uint32_t                          propertiesCount, VkDataGraphPipelinePropertyQueryResultARM* pProperties);
    VkResult vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM(VkPhysicalDevice                     physicalDevice, uint32_t                             queueFamilyIndex, uint32_t*                            pQueueFamilyDataGraphPropertyCount, VkQueueFamilyDataGraphPropertiesARM* pQueueFamilyDataGraphProperties);
    void vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM(VkPhysicalDevice                                 physicalDevice, VkPhysicalDeviceQueueFamilyDataGraphProcessingEngineInfoARM* pQueueFamilyDataGraphProcessingEngineInfo, VkQueueFamilyDataGraphProcessingEnginePropertiesARM*               pQueueFamilyDataGraphProcessingEngineProperties);
    VkResult vkGetNativeBufferPropertiesOHOS(VkDevice device, struct OH_NativeBuffer* buffer, VkNativeBufferPropertiesOHOS* pProperties);
    VkResult vkGetMemoryNativeBufferOHOS(VkDevice device, VkMemoryGetNativeBufferInfoOHOS* pInfo, struct OH_NativeBuffer** pBuffer);
    VkResult vkGetSwapchainGrallocUsageOHOS(VkDevice device, VkFormat format, VkImageUsageFlags imageUsage, uint64_t* grallocUsage);
    VkResult vkAcquireImageOHOS(VkDevice device, VkImage image, int32_t nativeFenceFd, VkSemaphore semaphore, VkFence fence);
    VkResult vkQueueSignalReleaseImageOHOS(VkQueue queue, uint32_t waitSemaphoreCount, VkSemaphore* pWaitSemaphores, VkImage image, int32_t* pNativeFenceFd);
    VkResult vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, uint32_t* pCounterCount, VkPerformanceCounterARM* pCounters, VkPerformanceCounterDescriptionARM* pCounterDescriptions);
    void vkCmdSetComputeOccupancyPriorityNV(VkCommandBuffer commandBuffer, VkComputeOccupancyPriorityParametersNV* pParameters);
    VkResult vkWriteSamplerDescriptorsEXT(VkDevice                                            device, uint32_t                                            samplerCount, VkSamplerCreateInfo*       pSamplers, VkHostAddressRangeEXT*     pDescriptors);
    VkResult vkWriteResourceDescriptorsEXT(VkDevice                                                device, uint32_t                                                resourceCount, VkResourceDescriptorInfoEXT*  pResources, VkHostAddressRangeEXT*        pDescriptors);
    void vkCmdBindSamplerHeapEXT(VkCommandBuffer                   commandBuffer, VkBindHeapInfoEXT*                            pBindInfo);
    void vkCmdBindResourceHeapEXT(VkCommandBuffer                   commandBuffer, VkBindHeapInfoEXT*                            pBindInfo);
    void vkCmdPushDataEXT(VkCommandBuffer                   commandBuffer, VkPushDataInfoEXT*                            pPushDataInfo);
    VkResult vkRegisterCustomBorderColorEXT(VkDevice                                            device, VkSamplerCustomBorderColorCreateInfoEXT*      pBorderColor, VkBool32                                            requestIndex, uint32_t*                                           pIndex);
    void vkUnregisterCustomBorderColorEXT(VkDevice                                            device, uint32_t                                            index);
    VkResult vkGetImageOpaqueCaptureDataEXT(VkDevice                                            device, uint32_t                                            imageCount, VkImage*                     pImages, VkHostAddressRangeEXT*             pDatas);
    VkDeviceSize vkGetPhysicalDeviceDescriptorSizeEXT(VkPhysicalDevice                                    physicalDevice, VkDescriptorType                                    descriptorType);
    VkResult vkGetTensorOpaqueCaptureDataARM(VkDevice                                            device, uint32_t                                            tensorCount, VkTensorARM*                pTensors, VkHostAddressRangeEXT*            pDatas);
]]

local ffi_lib = ffi.load('vulkan')
local M = { _lib = ffi_lib }
M.VK_MAX_PHYSICAL_DEVICE_NAME_SIZE = 256
M.VK_UUID_SIZE = 16
M.VK_LUID_SIZE = 8
M.VK_MAX_EXTENSION_NAME_SIZE = 256
M.VK_MAX_DESCRIPTION_SIZE = 256
M.VK_MAX_MEMORY_TYPES = 32
M.VK_MAX_MEMORY_HEAPS = 16
M.VK_LOD_CLAMP_NONE = 1000.0
M.VK_REMAINING_MIP_LEVELS = 0xFFFFFFFFFFFFFFFFULL
M.VK_REMAINING_ARRAY_LAYERS = 0xFFFFFFFFFFFFFFFFULL
M.VK_REMAINING_3D_SLICES_EXT = 0xFFFFFFFFFFFFFFFFULL
M.VK_WHOLE_SIZE = 0xFFFFFFFFFFFFFFFFULL
M.VK_ATTACHMENT_UNUSED = 0xFFFFFFFFFFFFFFFFULL
M.VK_TRUE = 1
M.VK_FALSE = 0
M.VK_QUEUE_FAMILY_IGNORED = 0xFFFFFFFFFFFFFFFFULL
M.VK_QUEUE_FAMILY_EXTERNAL = 0xFFFFFFFFFFFFFFFEULL
M.VK_QUEUE_FAMILY_FOREIGN_EXT = 0xFFFFFFFFFFFFFFFDULL
M.VK_SUBPASS_EXTERNAL = 0xFFFFFFFFFFFFFFFFULL
M.VK_MAX_DEVICE_GROUP_SIZE = 32
M.VK_MAX_DRIVER_NAME_SIZE = 256
M.VK_MAX_DRIVER_INFO_SIZE = 256
M.VK_SHADER_UNUSED_KHR = 0xFFFFFFFFFFFFFFFFULL
M.VK_MAX_GLOBAL_PRIORITY_SIZE = 16
M.VK_MAX_SHADER_MODULE_IDENTIFIER_SIZE_EXT = 32
M.VK_MAX_PIPELINE_BINARY_KEY_SIZE_KHR = 32
M.VK_MAX_VIDEO_AV1_REFERENCES_PER_FRAME_KHR = 7
M.VK_MAX_VIDEO_VP9_REFERENCES_PER_FRAME_KHR = 3
M.VK_SHADER_INDEX_UNUSED_AMDX = 0xFFFFFFFFFFFFFFFFULL
M.VK_PARTITIONED_ACCELERATION_STRUCTURE_PARTITION_INDEX_GLOBAL_NV = 0xFFFFFFFFFFFFFFFFULL
M.VK_COMPRESSED_TRIANGLE_FORMAT_DGF1_BYTE_ALIGNMENT_AMDX = 128
M.VK_COMPRESSED_TRIANGLE_FORMAT_DGF1_BYTE_STRIDE_AMDX = 128
M.VK_MAX_PHYSICAL_DEVICE_DATA_GRAPH_OPERATION_SET_NAME_SIZE_ARM = 128
M.VK_DATA_GRAPH_MODEL_TOOLCHAIN_VERSION_LENGTH_QCOM = 3
M.VK_COMPUTE_OCCUPANCY_PRIORITY_LOW_NV = 0.25
M.VK_COMPUTE_OCCUPANCY_PRIORITY_NORMAL_NV = 0.50
M.VK_COMPUTE_OCCUPANCY_PRIORITY_HIGH_NV = 0.75
M.VK_IMAGE_LAYOUT_UNDEFINED = 0
M.VK_IMAGE_LAYOUT_GENERAL = 1
M.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL = 2
M.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL = 3
M.VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL = 4
M.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL = 5
M.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL = 6
M.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL = 7
M.VK_IMAGE_LAYOUT_PREINITIALIZED = 8
M.VK_ATTACHMENT_LOAD_OP_LOAD = 0
M.VK_ATTACHMENT_LOAD_OP_CLEAR = 1
M.VK_ATTACHMENT_LOAD_OP_DONT_CARE = 2
M.VK_ATTACHMENT_STORE_OP_STORE = 0
M.VK_ATTACHMENT_STORE_OP_DONT_CARE = 1
M.VK_IMAGE_TYPE_1D = 0
M.VK_IMAGE_TYPE_2D = 1
M.VK_IMAGE_TYPE_3D = 2
M.VK_IMAGE_TILING_OPTIMAL = 0
M.VK_IMAGE_TILING_LINEAR = 1
M.VK_IMAGE_VIEW_TYPE_1D = 0
M.VK_IMAGE_VIEW_TYPE_2D = 1
M.VK_IMAGE_VIEW_TYPE_3D = 2
M.VK_IMAGE_VIEW_TYPE_CUBE = 3
M.VK_IMAGE_VIEW_TYPE_1D_ARRAY = 4
M.VK_IMAGE_VIEW_TYPE_2D_ARRAY = 5
M.VK_IMAGE_VIEW_TYPE_CUBE_ARRAY = 6
M.VK_COMMAND_BUFFER_LEVEL_PRIMARY = 0
M.VK_COMMAND_BUFFER_LEVEL_SECONDARY = 1
M.VK_COMPONENT_SWIZZLE_IDENTITY = 0
M.VK_COMPONENT_SWIZZLE_ZERO = 1
M.VK_COMPONENT_SWIZZLE_ONE = 2
M.VK_COMPONENT_SWIZZLE_R = 3
M.VK_COMPONENT_SWIZZLE_G = 4
M.VK_COMPONENT_SWIZZLE_B = 5
M.VK_COMPONENT_SWIZZLE_A = 6
M.VK_DESCRIPTOR_TYPE_SAMPLER = 0
M.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER = 1
M.VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE = 2
M.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE = 3
M.VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER = 4
M.VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER = 5
M.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER = 6
M.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER = 7
M.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC = 8
M.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC = 9
M.VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT = 10
M.VK_QUERY_TYPE_OCCLUSION = 0
M.VK_QUERY_TYPE_PIPELINE_STATISTICS = 1
M.VK_QUERY_TYPE_TIMESTAMP = 2
M.VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK = 0
M.VK_BORDER_COLOR_INT_TRANSPARENT_BLACK = 1
M.VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK = 2
M.VK_BORDER_COLOR_INT_OPAQUE_BLACK = 3
M.VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE = 4
M.VK_BORDER_COLOR_INT_OPAQUE_WHITE = 5
M.VK_PIPELINE_BIND_POINT_GRAPHICS = 0
M.VK_PIPELINE_BIND_POINT_COMPUTE = 1
M.VK_PIPELINE_CACHE_HEADER_VERSION_ONE = 1
M.VK_PRIMITIVE_TOPOLOGY_POINT_LIST = 0
M.VK_PRIMITIVE_TOPOLOGY_LINE_LIST = 1
M.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP = 2
M.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST = 3
M.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP = 4
M.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_FAN = 5
M.VK_PRIMITIVE_TOPOLOGY_LINE_LIST_WITH_ADJACENCY = 6
M.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP_WITH_ADJACENCY = 7
M.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST_WITH_ADJACENCY = 8
M.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP_WITH_ADJACENCY = 9
M.VK_PRIMITIVE_TOPOLOGY_PATCH_LIST = 10
M.VK_SHARING_MODE_EXCLUSIVE = 0
M.VK_SHARING_MODE_CONCURRENT = 1
M.VK_INDEX_TYPE_UINT16 = 0
M.VK_INDEX_TYPE_UINT32 = 1
M.VK_FILTER_NEAREST = 0
M.VK_FILTER_LINEAR = 1
M.VK_SAMPLER_MIPMAP_MODE_NEAREST = 0
M.VK_SAMPLER_MIPMAP_MODE_LINEAR = 1
M.VK_SAMPLER_ADDRESS_MODE_REPEAT = 0
M.VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT = 1
M.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE = 2
M.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER = 3
M.VK_COMPARE_OP_NEVER = 0
M.VK_COMPARE_OP_LESS = 1
M.VK_COMPARE_OP_EQUAL = 2
M.VK_COMPARE_OP_LESS_OR_EQUAL = 3
M.VK_COMPARE_OP_GREATER = 4
M.VK_COMPARE_OP_NOT_EQUAL = 5
M.VK_COMPARE_OP_GREATER_OR_EQUAL = 6
M.VK_COMPARE_OP_ALWAYS = 7
M.VK_POLYGON_MODE_FILL = 0
M.VK_POLYGON_MODE_LINE = 1
M.VK_POLYGON_MODE_POINT = 2
M.VK_FRONT_FACE_COUNTER_CLOCKWISE = 0
M.VK_FRONT_FACE_CLOCKWISE = 1
M.VK_BLEND_FACTOR_ZERO = 0
M.VK_BLEND_FACTOR_ONE = 1
M.VK_BLEND_FACTOR_SRC_COLOR = 2
M.VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR = 3
M.VK_BLEND_FACTOR_DST_COLOR = 4
M.VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR = 5
M.VK_BLEND_FACTOR_SRC_ALPHA = 6
M.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA = 7
M.VK_BLEND_FACTOR_DST_ALPHA = 8
M.VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA = 9
M.VK_BLEND_FACTOR_CONSTANT_COLOR = 10
M.VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR = 11
M.VK_BLEND_FACTOR_CONSTANT_ALPHA = 12
M.VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA = 13
M.VK_BLEND_FACTOR_SRC_ALPHA_SATURATE = 14
M.VK_BLEND_FACTOR_SRC1_COLOR = 15
M.VK_BLEND_FACTOR_ONE_MINUS_SRC1_COLOR = 16
M.VK_BLEND_FACTOR_SRC1_ALPHA = 17
M.VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA = 18
M.VK_BLEND_OP_ADD = 0
M.VK_BLEND_OP_SUBTRACT = 1
M.VK_BLEND_OP_REVERSE_SUBTRACT = 2
M.VK_BLEND_OP_MIN = 3
M.VK_BLEND_OP_MAX = 4
M.VK_STENCIL_OP_KEEP = 0
M.VK_STENCIL_OP_ZERO = 1
M.VK_STENCIL_OP_REPLACE = 2
M.VK_STENCIL_OP_INCREMENT_AND_CLAMP = 3
M.VK_STENCIL_OP_DECREMENT_AND_CLAMP = 4
M.VK_STENCIL_OP_INVERT = 5
M.VK_STENCIL_OP_INCREMENT_AND_WRAP = 6
M.VK_STENCIL_OP_DECREMENT_AND_WRAP = 7
M.VK_LOGIC_OP_CLEAR = 0
M.VK_LOGIC_OP_AND = 1
M.VK_LOGIC_OP_AND_REVERSE = 2
M.VK_LOGIC_OP_COPY = 3
M.VK_LOGIC_OP_AND_INVERTED = 4
M.VK_LOGIC_OP_NO_OP = 5
M.VK_LOGIC_OP_XOR = 6
M.VK_LOGIC_OP_OR = 7
M.VK_LOGIC_OP_NOR = 8
M.VK_LOGIC_OP_EQUIVALENT = 9
M.VK_LOGIC_OP_INVERT = 10
M.VK_LOGIC_OP_OR_REVERSE = 11
M.VK_LOGIC_OP_COPY_INVERTED = 12
M.VK_LOGIC_OP_OR_INVERTED = 13
M.VK_LOGIC_OP_NAND = 14
M.VK_LOGIC_OP_SET = 15
M.VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE = 0
M.VK_SYSTEM_ALLOCATION_SCOPE_COMMAND = 0
M.VK_SYSTEM_ALLOCATION_SCOPE_OBJECT = 1
M.VK_SYSTEM_ALLOCATION_SCOPE_CACHE = 2
M.VK_SYSTEM_ALLOCATION_SCOPE_DEVICE = 3
M.VK_SYSTEM_ALLOCATION_SCOPE_INSTANCE = 4
M.VK_PHYSICAL_DEVICE_TYPE_OTHER = 0
M.VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU = 1
M.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU = 2
M.VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU = 3
M.VK_PHYSICAL_DEVICE_TYPE_CPU = 4
M.VK_VERTEX_INPUT_RATE_VERTEX = 0
M.VK_VERTEX_INPUT_RATE_INSTANCE = 1
M.VK_FORMAT_UNDEFINED = 0
M.VK_FORMAT_R4G4_UNORM_PACK8 = 1
M.VK_FORMAT_R4G4B4A4_UNORM_PACK16 = 2
M.VK_FORMAT_B4G4R4A4_UNORM_PACK16 = 3
M.VK_FORMAT_R5G6B5_UNORM_PACK16 = 4
M.VK_FORMAT_B5G6R5_UNORM_PACK16 = 5
M.VK_FORMAT_R5G5B5A1_UNORM_PACK16 = 6
M.VK_FORMAT_B5G5R5A1_UNORM_PACK16 = 7
M.VK_FORMAT_A1R5G5B5_UNORM_PACK16 = 8
M.VK_FORMAT_R8_UNORM = 9
M.VK_FORMAT_R8_SNORM = 10
M.VK_FORMAT_R8_USCALED = 11
M.VK_FORMAT_R8_SSCALED = 12
M.VK_FORMAT_R8_UINT = 13
M.VK_FORMAT_R8_SINT = 14
M.VK_FORMAT_R8_SRGB = 15
M.VK_FORMAT_R8G8_UNORM = 16
M.VK_FORMAT_R8G8_SNORM = 17
M.VK_FORMAT_R8G8_USCALED = 18
M.VK_FORMAT_R8G8_SSCALED = 19
M.VK_FORMAT_R8G8_UINT = 20
M.VK_FORMAT_R8G8_SINT = 21
M.VK_FORMAT_R8G8_SRGB = 22
M.VK_FORMAT_R8G8B8_UNORM = 23
M.VK_FORMAT_R8G8B8_SNORM = 24
M.VK_FORMAT_R8G8B8_USCALED = 25
M.VK_FORMAT_R8G8B8_SSCALED = 26
M.VK_FORMAT_R8G8B8_UINT = 27
M.VK_FORMAT_R8G8B8_SINT = 28
M.VK_FORMAT_R8G8B8_SRGB = 29
M.VK_FORMAT_B8G8R8_UNORM = 30
M.VK_FORMAT_B8G8R8_SNORM = 31
M.VK_FORMAT_B8G8R8_USCALED = 32
M.VK_FORMAT_B8G8R8_SSCALED = 33
M.VK_FORMAT_B8G8R8_UINT = 34
M.VK_FORMAT_B8G8R8_SINT = 35
M.VK_FORMAT_B8G8R8_SRGB = 36
M.VK_FORMAT_R8G8B8A8_UNORM = 37
M.VK_FORMAT_R8G8B8A8_SNORM = 38
M.VK_FORMAT_R8G8B8A8_USCALED = 39
M.VK_FORMAT_R8G8B8A8_SSCALED = 40
M.VK_FORMAT_R8G8B8A8_UINT = 41
M.VK_FORMAT_R8G8B8A8_SINT = 42
M.VK_FORMAT_R8G8B8A8_SRGB = 43
M.VK_FORMAT_B8G8R8A8_UNORM = 44
M.VK_FORMAT_B8G8R8A8_SNORM = 45
M.VK_FORMAT_B8G8R8A8_USCALED = 46
M.VK_FORMAT_B8G8R8A8_SSCALED = 47
M.VK_FORMAT_B8G8R8A8_UINT = 48
M.VK_FORMAT_B8G8R8A8_SINT = 49
M.VK_FORMAT_B8G8R8A8_SRGB = 50
M.VK_FORMAT_A8B8G8R8_UNORM_PACK32 = 51
M.VK_FORMAT_A8B8G8R8_SNORM_PACK32 = 52
M.VK_FORMAT_A8B8G8R8_USCALED_PACK32 = 53
M.VK_FORMAT_A8B8G8R8_SSCALED_PACK32 = 54
M.VK_FORMAT_A8B8G8R8_UINT_PACK32 = 55
M.VK_FORMAT_A8B8G8R8_SINT_PACK32 = 56
M.VK_FORMAT_A8B8G8R8_SRGB_PACK32 = 57
M.VK_FORMAT_A2R10G10B10_UNORM_PACK32 = 58
M.VK_FORMAT_A2R10G10B10_SNORM_PACK32 = 59
M.VK_FORMAT_A2R10G10B10_USCALED_PACK32 = 60
M.VK_FORMAT_A2R10G10B10_SSCALED_PACK32 = 61
M.VK_FORMAT_A2R10G10B10_UINT_PACK32 = 62
M.VK_FORMAT_A2R10G10B10_SINT_PACK32 = 63
M.VK_FORMAT_A2B10G10R10_UNORM_PACK32 = 64
M.VK_FORMAT_A2B10G10R10_SNORM_PACK32 = 65
M.VK_FORMAT_A2B10G10R10_USCALED_PACK32 = 66
M.VK_FORMAT_A2B10G10R10_SSCALED_PACK32 = 67
M.VK_FORMAT_A2B10G10R10_UINT_PACK32 = 68
M.VK_FORMAT_A2B10G10R10_SINT_PACK32 = 69
M.VK_FORMAT_R16_UNORM = 70
M.VK_FORMAT_R16_SNORM = 71
M.VK_FORMAT_R16_USCALED = 72
M.VK_FORMAT_R16_SSCALED = 73
M.VK_FORMAT_R16_UINT = 74
M.VK_FORMAT_R16_SINT = 75
M.VK_FORMAT_R16_SFLOAT = 76
M.VK_FORMAT_R16G16_UNORM = 77
M.VK_FORMAT_R16G16_SNORM = 78
M.VK_FORMAT_R16G16_USCALED = 79
M.VK_FORMAT_R16G16_SSCALED = 80
M.VK_FORMAT_R16G16_UINT = 81
M.VK_FORMAT_R16G16_SINT = 82
M.VK_FORMAT_R16G16_SFLOAT = 83
M.VK_FORMAT_R16G16B16_UNORM = 84
M.VK_FORMAT_R16G16B16_SNORM = 85
M.VK_FORMAT_R16G16B16_USCALED = 86
M.VK_FORMAT_R16G16B16_SSCALED = 87
M.VK_FORMAT_R16G16B16_UINT = 88
M.VK_FORMAT_R16G16B16_SINT = 89
M.VK_FORMAT_R16G16B16_SFLOAT = 90
M.VK_FORMAT_R16G16B16A16_UNORM = 91
M.VK_FORMAT_R16G16B16A16_SNORM = 92
M.VK_FORMAT_R16G16B16A16_USCALED = 93
M.VK_FORMAT_R16G16B16A16_SSCALED = 94
M.VK_FORMAT_R16G16B16A16_UINT = 95
M.VK_FORMAT_R16G16B16A16_SINT = 96
M.VK_FORMAT_R16G16B16A16_SFLOAT = 97
M.VK_FORMAT_R32_UINT = 98
M.VK_FORMAT_R32_SINT = 99
M.VK_FORMAT_R32_SFLOAT = 100
M.VK_FORMAT_R32G32_UINT = 101
M.VK_FORMAT_R32G32_SINT = 102
M.VK_FORMAT_R32G32_SFLOAT = 103
M.VK_FORMAT_R32G32B32_UINT = 104
M.VK_FORMAT_R32G32B32_SINT = 105
M.VK_FORMAT_R32G32B32_SFLOAT = 106
M.VK_FORMAT_R32G32B32A32_UINT = 107
M.VK_FORMAT_R32G32B32A32_SINT = 108
M.VK_FORMAT_R32G32B32A32_SFLOAT = 109
M.VK_FORMAT_R64_UINT = 110
M.VK_FORMAT_R64_SINT = 111
M.VK_FORMAT_R64_SFLOAT = 112
M.VK_FORMAT_R64G64_UINT = 113
M.VK_FORMAT_R64G64_SINT = 114
M.VK_FORMAT_R64G64_SFLOAT = 115
M.VK_FORMAT_R64G64B64_UINT = 116
M.VK_FORMAT_R64G64B64_SINT = 117
M.VK_FORMAT_R64G64B64_SFLOAT = 118
M.VK_FORMAT_R64G64B64A64_UINT = 119
M.VK_FORMAT_R64G64B64A64_SINT = 120
M.VK_FORMAT_R64G64B64A64_SFLOAT = 121
M.VK_FORMAT_B10G11R11_UFLOAT_PACK32 = 122
M.VK_FORMAT_E5B9G9R9_UFLOAT_PACK32 = 123
M.VK_FORMAT_D16_UNORM = 124
M.VK_FORMAT_X8_D24_UNORM_PACK32 = 125
M.VK_FORMAT_D32_SFLOAT = 126
M.VK_FORMAT_S8_UINT = 127
M.VK_FORMAT_D16_UNORM_S8_UINT = 128
M.VK_FORMAT_D24_UNORM_S8_UINT = 129
M.VK_FORMAT_D32_SFLOAT_S8_UINT = 130
M.VK_FORMAT_BC1_RGB_UNORM_BLOCK = 131
M.VK_FORMAT_BC1_RGB_SRGB_BLOCK = 132
M.VK_FORMAT_BC1_RGBA_UNORM_BLOCK = 133
M.VK_FORMAT_BC1_RGBA_SRGB_BLOCK = 134
M.VK_FORMAT_BC2_UNORM_BLOCK = 135
M.VK_FORMAT_BC2_SRGB_BLOCK = 136
M.VK_FORMAT_BC3_UNORM_BLOCK = 137
M.VK_FORMAT_BC3_SRGB_BLOCK = 138
M.VK_FORMAT_BC4_UNORM_BLOCK = 139
M.VK_FORMAT_BC4_SNORM_BLOCK = 140
M.VK_FORMAT_BC5_UNORM_BLOCK = 141
M.VK_FORMAT_BC5_SNORM_BLOCK = 142
M.VK_FORMAT_BC6H_UFLOAT_BLOCK = 143
M.VK_FORMAT_BC6H_SFLOAT_BLOCK = 144
M.VK_FORMAT_BC7_UNORM_BLOCK = 145
M.VK_FORMAT_BC7_SRGB_BLOCK = 146
M.VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK = 147
M.VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK = 148
M.VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK = 149
M.VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK = 150
M.VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK = 151
M.VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK = 152
M.VK_FORMAT_EAC_R11_UNORM_BLOCK = 153
M.VK_FORMAT_EAC_R11_SNORM_BLOCK = 154
M.VK_FORMAT_EAC_R11G11_UNORM_BLOCK = 155
M.VK_FORMAT_EAC_R11G11_SNORM_BLOCK = 156
M.VK_FORMAT_ASTC_4x4_UNORM_BLOCK = 157
M.VK_FORMAT_ASTC_4x4_SRGB_BLOCK = 158
M.VK_FORMAT_ASTC_5x4_UNORM_BLOCK = 159
M.VK_FORMAT_ASTC_5x4_SRGB_BLOCK = 160
M.VK_FORMAT_ASTC_5x5_UNORM_BLOCK = 161
M.VK_FORMAT_ASTC_5x5_SRGB_BLOCK = 162
M.VK_FORMAT_ASTC_6x5_UNORM_BLOCK = 163
M.VK_FORMAT_ASTC_6x5_SRGB_BLOCK = 164
M.VK_FORMAT_ASTC_6x6_UNORM_BLOCK = 165
M.VK_FORMAT_ASTC_6x6_SRGB_BLOCK = 166
M.VK_FORMAT_ASTC_8x5_UNORM_BLOCK = 167
M.VK_FORMAT_ASTC_8x5_SRGB_BLOCK = 168
M.VK_FORMAT_ASTC_8x6_UNORM_BLOCK = 169
M.VK_FORMAT_ASTC_8x6_SRGB_BLOCK = 170
M.VK_FORMAT_ASTC_8x8_UNORM_BLOCK = 171
M.VK_FORMAT_ASTC_8x8_SRGB_BLOCK = 172
M.VK_FORMAT_ASTC_10x5_UNORM_BLOCK = 173
M.VK_FORMAT_ASTC_10x5_SRGB_BLOCK = 174
M.VK_FORMAT_ASTC_10x6_UNORM_BLOCK = 175
M.VK_FORMAT_ASTC_10x6_SRGB_BLOCK = 176
M.VK_FORMAT_ASTC_10x8_UNORM_BLOCK = 177
M.VK_FORMAT_ASTC_10x8_SRGB_BLOCK = 178
M.VK_FORMAT_ASTC_10x10_UNORM_BLOCK = 179
M.VK_FORMAT_ASTC_10x10_SRGB_BLOCK = 180
M.VK_FORMAT_ASTC_12x10_UNORM_BLOCK = 181
M.VK_FORMAT_ASTC_12x10_SRGB_BLOCK = 182
M.VK_FORMAT_ASTC_12x12_UNORM_BLOCK = 183
M.VK_FORMAT_ASTC_12x12_SRGB_BLOCK = 184
M.VK_STRUCTURE_TYPE_APPLICATION_INFO = 0
M.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO = 1
M.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO = 2
M.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO = 3
M.VK_STRUCTURE_TYPE_SUBMIT_INFO = 4
M.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO = 5
M.VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE = 6
M.VK_STRUCTURE_TYPE_BIND_SPARSE_INFO = 7
M.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO = 8
M.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO = 9
M.VK_STRUCTURE_TYPE_EVENT_CREATE_INFO = 10
M.VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO = 11
M.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO = 12
M.VK_STRUCTURE_TYPE_BUFFER_VIEW_CREATE_INFO = 13
M.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO = 14
M.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO = 15
M.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO = 16
M.VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO = 17
M.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO = 18
M.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO = 19
M.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO = 20
M.VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO = 21
M.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO = 22
M.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO = 23
M.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO = 24
M.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO = 25
M.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO = 26
M.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO = 27
M.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO = 28
M.VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO = 29
M.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO = 30
M.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO = 31
M.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO = 32
M.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO = 33
M.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO = 34
M.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET = 35
M.VK_STRUCTURE_TYPE_COPY_DESCRIPTOR_SET = 36
M.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO = 37
M.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO = 38
M.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO = 39
M.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO = 40
M.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO = 41
M.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO = 42
M.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO = 43
M.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER = 44
M.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER = 45
M.VK_STRUCTURE_TYPE_MEMORY_BARRIER = 46
M.VK_STRUCTURE_TYPE_LOADER_INSTANCE_CREATE_INFO = 47
M.VK_STRUCTURE_TYPE_LOADER_DEVICE_CREATE_INFO = 48
M.VK_SUBPASS_CONTENTS_INLINE = 0
M.VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS = 1
M.VK_SUCCESS = 0
M.VK_NOT_READY = 1
M.VK_TIMEOUT = 2
M.VK_EVENT_SET = 3
M.VK_EVENT_RESET = 4
M.VK_INCOMPLETE = 5
M.VK_ERROR_OUT_OF_HOST_MEMORY = -1
M.VK_ERROR_OUT_OF_DEVICE_MEMORY = -2
M.VK_ERROR_INITIALIZATION_FAILED = -3
M.VK_ERROR_DEVICE_LOST = -4
M.VK_ERROR_MEMORY_MAP_FAILED = -5
M.VK_ERROR_LAYER_NOT_PRESENT = -6
M.VK_ERROR_EXTENSION_NOT_PRESENT = -7
M.VK_ERROR_FEATURE_NOT_PRESENT = -8
M.VK_ERROR_INCOMPATIBLE_DRIVER = -9
M.VK_ERROR_TOO_MANY_OBJECTS = -10
M.VK_ERROR_FORMAT_NOT_SUPPORTED = -11
M.VK_ERROR_FRAGMENTED_POOL = -12
M.VK_ERROR_UNKNOWN = -13
M.VK_DYNAMIC_STATE_VIEWPORT = 0
M.VK_DYNAMIC_STATE_SCISSOR = 1
M.VK_DYNAMIC_STATE_LINE_WIDTH = 2
M.VK_DYNAMIC_STATE_DEPTH_BIAS = 3
M.VK_DYNAMIC_STATE_BLEND_CONSTANTS = 4
M.VK_DYNAMIC_STATE_DEPTH_BOUNDS = 5
M.VK_DYNAMIC_STATE_STENCIL_COMPARE_MASK = 6
M.VK_DYNAMIC_STATE_STENCIL_WRITE_MASK = 7
M.VK_DYNAMIC_STATE_STENCIL_REFERENCE = 8
M.VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET = 0
M.VK_OBJECT_TYPE_UNKNOWN = 0
M.VK_OBJECT_TYPE_INSTANCE = 1
M.VK_OBJECT_TYPE_PHYSICAL_DEVICE = 2
M.VK_OBJECT_TYPE_DEVICE = 3
M.VK_OBJECT_TYPE_QUEUE = 4
M.VK_OBJECT_TYPE_SEMAPHORE = 5
M.VK_OBJECT_TYPE_COMMAND_BUFFER = 6
M.VK_OBJECT_TYPE_FENCE = 7
M.VK_OBJECT_TYPE_DEVICE_MEMORY = 8
M.VK_OBJECT_TYPE_BUFFER = 9
M.VK_OBJECT_TYPE_IMAGE = 10
M.VK_OBJECT_TYPE_EVENT = 11
M.VK_OBJECT_TYPE_QUERY_POOL = 12
M.VK_OBJECT_TYPE_BUFFER_VIEW = 13
M.VK_OBJECT_TYPE_IMAGE_VIEW = 14
M.VK_OBJECT_TYPE_SHADER_MODULE = 15
M.VK_OBJECT_TYPE_PIPELINE_CACHE = 16
M.VK_OBJECT_TYPE_PIPELINE_LAYOUT = 17
M.VK_OBJECT_TYPE_RENDER_PASS = 18
M.VK_OBJECT_TYPE_PIPELINE = 19
M.VK_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT = 20
M.VK_OBJECT_TYPE_SAMPLER = 21
M.VK_OBJECT_TYPE_DESCRIPTOR_POOL = 22
M.VK_OBJECT_TYPE_DESCRIPTOR_SET = 23
M.VK_OBJECT_TYPE_FRAMEBUFFER = 24
M.VK_OBJECT_TYPE_COMMAND_POOL = 25
M.VK_RAY_TRACING_INVOCATION_REORDER_MODE_NONE_EXT = 0
M.VK_RAY_TRACING_INVOCATION_REORDER_MODE_REORDER_EXT = 1
M.VK_RAY_TRACING_LSS_INDEXING_MODE_LIST_NV = 0
M.VK_RAY_TRACING_LSS_INDEXING_MODE_SUCCESSIVE_NV = 1
M.VK_RAY_TRACING_LSS_PRIMITIVE_END_CAPS_MODE_NONE_NV = 0
M.VK_RAY_TRACING_LSS_PRIMITIVE_END_CAPS_MODE_CHAINED_NV = 1
M.VK_DIRECT_DRIVER_LOADING_MODE_EXCLUSIVE_LUNARG = 0
M.VK_DIRECT_DRIVER_LOADING_MODE_INCLUSIVE_LUNARG = 1
M.VK_ANTI_LAG_MODE_DRIVER_CONTROL_AMD = 0
M.VK_ANTI_LAG_MODE_ON_AMD = 1
M.VK_ANTI_LAG_MODE_OFF_AMD = 2
M.VK_ANTI_LAG_STAGE_INPUT_AMD = 0
M.VK_ANTI_LAG_STAGE_PRESENT_AMD = 1
M.VK_QUEUE_GRAPHICS_BIT = 1
M.VK_QUEUE_COMPUTE_BIT = 2
M.VK_QUEUE_TRANSFER_BIT = 4
M.VK_QUEUE_SPARSE_BINDING_BIT = 8
M.VK_CULL_MODE_NONE = 0
M.VK_CULL_MODE_FRONT_BIT = 1
M.VK_CULL_MODE_BACK_BIT = 2
M.VK_CULL_MODE_FRONT_AND_BACK = 0x00000003
M.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT = 1
M.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT = 2
M.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT = 4
M.VK_MEMORY_PROPERTY_HOST_CACHED_BIT = 8
M.VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT = 16
M.VK_MEMORY_HEAP_DEVICE_LOCAL_BIT = 1
M.VK_ACCESS_INDIRECT_COMMAND_READ_BIT = 1
M.VK_ACCESS_INDEX_READ_BIT = 2
M.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT = 4
M.VK_ACCESS_UNIFORM_READ_BIT = 8
M.VK_ACCESS_INPUT_ATTACHMENT_READ_BIT = 16
M.VK_ACCESS_SHADER_READ_BIT = 32
M.VK_ACCESS_SHADER_WRITE_BIT = 64
M.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT = 128
M.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT = 256
M.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT = 512
M.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT = 1024
M.VK_ACCESS_TRANSFER_READ_BIT = 2048
M.VK_ACCESS_TRANSFER_WRITE_BIT = 4096
M.VK_ACCESS_HOST_READ_BIT = 8192
M.VK_ACCESS_HOST_WRITE_BIT = 16384
M.VK_ACCESS_MEMORY_READ_BIT = 32768
M.VK_ACCESS_MEMORY_WRITE_BIT = 65536
M.VK_BUFFER_USAGE_TRANSFER_SRC_BIT = 1
M.VK_BUFFER_USAGE_TRANSFER_DST_BIT = 2
M.VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT = 4
M.VK_BUFFER_USAGE_STORAGE_TEXEL_BUFFER_BIT = 8
M.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT = 16
M.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT = 32
M.VK_BUFFER_USAGE_INDEX_BUFFER_BIT = 64
M.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT = 128
M.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT = 256
M.VK_BUFFER_USAGE_2_TRANSFER_SRC_BIT = 1
M.VK_BUFFER_USAGE_2_TRANSFER_DST_BIT = 2
M.VK_BUFFER_USAGE_2_UNIFORM_TEXEL_BUFFER_BIT = 4
M.VK_BUFFER_USAGE_2_STORAGE_TEXEL_BUFFER_BIT = 8
M.VK_BUFFER_USAGE_2_UNIFORM_BUFFER_BIT = 16
M.VK_BUFFER_USAGE_2_STORAGE_BUFFER_BIT = 32
M.VK_BUFFER_USAGE_2_INDEX_BUFFER_BIT = 64
M.VK_BUFFER_USAGE_2_VERTEX_BUFFER_BIT = 128
M.VK_BUFFER_USAGE_2_INDIRECT_BUFFER_BIT = 256
M.VK_BUFFER_CREATE_SPARSE_BINDING_BIT = 1
M.VK_BUFFER_CREATE_SPARSE_RESIDENCY_BIT = 2
M.VK_BUFFER_CREATE_SPARSE_ALIASED_BIT = 4
M.VK_SHADER_STAGE_VERTEX_BIT = 1
M.VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT = 2
M.VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT = 4
M.VK_SHADER_STAGE_GEOMETRY_BIT = 8
M.VK_SHADER_STAGE_FRAGMENT_BIT = 16
M.VK_SHADER_STAGE_COMPUTE_BIT = 32
M.VK_SHADER_STAGE_ALL_GRAPHICS = 0x0000001
M.VK_SHADER_STAGE_ALL = 0x7
M.VK_IMAGE_USAGE_TRANSFER_SRC_BIT = 1
M.VK_IMAGE_USAGE_TRANSFER_DST_BIT = 2
M.VK_IMAGE_USAGE_SAMPLED_BIT = 4
M.VK_IMAGE_USAGE_STORAGE_BIT = 8
M.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT = 16
M.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT = 32
M.VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT = 64
M.VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT = 128
M.VK_IMAGE_CREATE_SPARSE_BINDING_BIT = 1
M.VK_IMAGE_CREATE_SPARSE_RESIDENCY_BIT = 2
M.VK_IMAGE_CREATE_SPARSE_ALIASED_BIT = 4
M.VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT = 8
M.VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT = 16
M.VK_PIPELINE_CREATE_DISABLE_OPTIMIZATION_BIT = 1
M.VK_PIPELINE_CREATE_ALLOW_DERIVATIVES_BIT = 2
M.VK_PIPELINE_CREATE_DERIVATIVE_BIT = 4
M.VK_PIPELINE_CREATE_2_DISABLE_OPTIMIZATION_BIT = 1
M.VK_PIPELINE_CREATE_2_ALLOW_DERIVATIVES_BIT = 2
M.VK_PIPELINE_CREATE_2_DERIVATIVE_BIT = 4
M.VK_PIPELINE_CREATE_2_VIEW_INDEX_FROM_DEVICE_INDEX_BIT = 8
M.VK_PIPELINE_CREATE_2_DISPATCH_BASE_BIT = 16
M.VK_PIPELINE_CREATE_2_FAIL_ON_PIPELINE_COMPILE_REQUIRED_BIT = 256
M.VK_PIPELINE_CREATE_2_EARLY_RETURN_ON_FAILURE_BIT = 512
M.VK_PIPELINE_CREATE_2_NO_PROTECTED_ACCESS_BIT = 134217728
M.VK_PIPELINE_CREATE_2_PROTECTED_ACCESS_ONLY_BIT = 1073741824
M.VK_COLOR_COMPONENT_R_BIT = 1
M.VK_COLOR_COMPONENT_G_BIT = 2
M.VK_COLOR_COMPONENT_B_BIT = 4
M.VK_COLOR_COMPONENT_A_BIT = 8
M.VK_FENCE_CREATE_SIGNALED_BIT = 1
M.VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT = 1
M.VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT = 2
M.VK_FORMAT_FEATURE_STORAGE_IMAGE_ATOMIC_BIT = 4
M.VK_FORMAT_FEATURE_UNIFORM_TEXEL_BUFFER_BIT = 8
M.VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_BIT = 16
M.VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_ATOMIC_BIT = 32
M.VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT = 64
M.VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT = 128
M.VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BLEND_BIT = 256
M.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT = 512
M.VK_FORMAT_FEATURE_BLIT_SRC_BIT = 1024
M.VK_FORMAT_FEATURE_BLIT_DST_BIT = 2048
M.VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT = 4096
M.VK_QUERY_CONTROL_PRECISE_BIT = 1
M.VK_QUERY_RESULT_64_BIT = 1
M.VK_QUERY_RESULT_WAIT_BIT = 2
M.VK_QUERY_RESULT_WITH_AVAILABILITY_BIT = 4
M.VK_QUERY_RESULT_PARTIAL_BIT = 8
M.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT = 1
M.VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT = 2
M.VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT = 4
M.VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_VERTICES_BIT = 1
M.VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_PRIMITIVES_BIT = 2
M.VK_QUERY_PIPELINE_STATISTIC_VERTEX_SHADER_INVOCATIONS_BIT = 4
M.VK_QUERY_PIPELINE_STATISTIC_GEOMETRY_SHADER_INVOCATIONS_BIT = 8
M.VK_QUERY_PIPELINE_STATISTIC_GEOMETRY_SHADER_PRIMITIVES_BIT = 16
M.VK_QUERY_PIPELINE_STATISTIC_CLIPPING_INVOCATIONS_BIT = 32
M.VK_QUERY_PIPELINE_STATISTIC_CLIPPING_PRIMITIVES_BIT = 64
M.VK_QUERY_PIPELINE_STATISTIC_FRAGMENT_SHADER_INVOCATIONS_BIT = 128
M.VK_QUERY_PIPELINE_STATISTIC_TESSELLATION_CONTROL_SHADER_PATCHES_BIT = 256
M.VK_QUERY_PIPELINE_STATISTIC_TESSELLATION_EVALUATION_SHADER_INVOCATIONS_BIT = 512
M.VK_QUERY_PIPELINE_STATISTIC_COMPUTE_SHADER_INVOCATIONS_BIT = 1024
M.VK_IMAGE_ASPECT_COLOR_BIT = 1
M.VK_IMAGE_ASPECT_DEPTH_BIT = 2
M.VK_IMAGE_ASPECT_STENCIL_BIT = 4
M.VK_IMAGE_ASPECT_METADATA_BIT = 8
M.VK_SPARSE_IMAGE_FORMAT_SINGLE_MIPTAIL_BIT = 1
M.VK_SPARSE_IMAGE_FORMAT_ALIGNED_MIP_SIZE_BIT = 2
M.VK_SPARSE_IMAGE_FORMAT_NONSTANDARD_BLOCK_SIZE_BIT = 4
M.VK_SPARSE_MEMORY_BIND_METADATA_BIT = 1
M.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT = 1
M.VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT = 2
M.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT = 4
M.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT = 8
M.VK_PIPELINE_STAGE_TESSELLATION_CONTROL_SHADER_BIT = 16
M.VK_PIPELINE_STAGE_TESSELLATION_EVALUATION_SHADER_BIT = 32
M.VK_PIPELINE_STAGE_GEOMETRY_SHADER_BIT = 64
M.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT = 128
M.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT = 256
M.VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT = 512
M.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT = 1024
M.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT = 2048
M.VK_PIPELINE_STAGE_TRANSFER_BIT = 4096
M.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT = 8192
M.VK_PIPELINE_STAGE_HOST_BIT = 16384
M.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT = 32768
M.VK_PIPELINE_STAGE_ALL_COMMANDS_BIT = 65536
M.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT = 1
M.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT = 2
M.VK_COMMAND_POOL_RESET_RELEASE_RESOURCES_BIT = 1
M.VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT = 1
M.VK_SAMPLE_COUNT_1_BIT = 1
M.VK_SAMPLE_COUNT_2_BIT = 2
M.VK_SAMPLE_COUNT_4_BIT = 4
M.VK_SAMPLE_COUNT_8_BIT = 8
M.VK_SAMPLE_COUNT_16_BIT = 16
M.VK_SAMPLE_COUNT_32_BIT = 32
M.VK_SAMPLE_COUNT_64_BIT = 64
M.VK_ATTACHMENT_DESCRIPTION_MAY_ALIAS_BIT = 1
M.VK_STENCIL_FACE_FRONT_BIT = 1
M.VK_STENCIL_FACE_BACK_BIT = 2
M.VK_STENCIL_FACE_FRONT_AND_BACK = 0x00000003
M.VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT = 1
M.VK_DEPENDENCY_BY_REGION_BIT = 1
M.VK_SEMAPHORE_TYPE_BINARY = 0
M.VK_SEMAPHORE_TYPE_TIMELINE = 1
M.VK_SEMAPHORE_WAIT_ANY_BIT = 1
M.VK_PRESENT_MODE_IMMEDIATE_KHR = 0
M.VK_PRESENT_MODE_MAILBOX_KHR = 1
M.VK_PRESENT_MODE_FIFO_KHR = 2
M.VK_PRESENT_MODE_FIFO_RELAXED_KHR = 3
M.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR = 0
M.VK_DISPLAY_PLANE_ALPHA_OPAQUE_BIT_KHR = 1
M.VK_DISPLAY_PLANE_ALPHA_GLOBAL_BIT_KHR = 2
M.VK_DISPLAY_PLANE_ALPHA_PER_PIXEL_BIT_KHR = 4
M.VK_DISPLAY_PLANE_ALPHA_PER_PIXEL_PREMULTIPLIED_BIT_KHR = 8
M.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR = 1
M.VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR = 2
M.VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR = 4
M.VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR = 8
M.VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR = 1
M.VK_SURFACE_TRANSFORM_ROTATE_90_BIT_KHR = 2
M.VK_SURFACE_TRANSFORM_ROTATE_180_BIT_KHR = 4
M.VK_SURFACE_TRANSFORM_ROTATE_270_BIT_KHR = 8
M.VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_BIT_KHR = 16
M.VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_90_BIT_KHR = 32
M.VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_180_BIT_KHR = 64
M.VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_270_BIT_KHR = 128
M.VK_SURFACE_TRANSFORM_INHERIT_BIT_KHR = 256
M.VK_DISPLAY_SURFACE_STEREO_TYPE_NONE_NV = 0
M.VK_DISPLAY_SURFACE_STEREO_TYPE_ONBOARD_DIN_NV = 1
M.VK_DISPLAY_SURFACE_STEREO_TYPE_HDMI_3D_NV = 2
M.VK_DISPLAY_SURFACE_STEREO_TYPE_INBAND_DISPLAYPORT_NV = 3
M.VK_SWAPCHAIN_IMAGE_USAGE_SHARED_BIT_ANDROID = 1
M.VK_TIME_DOMAIN_DEVICE_KHR = 0
M.VK_TIME_DOMAIN_CLOCK_MONOTONIC_KHR = 1
M.VK_TIME_DOMAIN_CLOCK_MONOTONIC_RAW_KHR = 2
M.VK_TIME_DOMAIN_QUERY_PERFORMANCE_COUNTER_KHR = 3
M.VK_DEBUG_REPORT_INFORMATION_BIT_EXT = 1
M.VK_DEBUG_REPORT_WARNING_BIT_EXT = 2
M.VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT = 4
M.VK_DEBUG_REPORT_ERROR_BIT_EXT = 8
M.VK_DEBUG_REPORT_DEBUG_BIT_EXT = 16
M.VK_DEBUG_REPORT_OBJECT_TYPE_UNKNOWN_EXT = 0
M.VK_DEBUG_REPORT_OBJECT_TYPE_INSTANCE_EXT = 1
M.VK_DEBUG_REPORT_OBJECT_TYPE_PHYSICAL_DEVICE_EXT = 2
M.VK_DEBUG_REPORT_OBJECT_TYPE_DEVICE_EXT = 3
M.VK_DEBUG_REPORT_OBJECT_TYPE_QUEUE_EXT = 4
M.VK_DEBUG_REPORT_OBJECT_TYPE_SEMAPHORE_EXT = 5
M.VK_DEBUG_REPORT_OBJECT_TYPE_COMMAND_BUFFER_EXT = 6
M.VK_DEBUG_REPORT_OBJECT_TYPE_FENCE_EXT = 7
M.VK_DEBUG_REPORT_OBJECT_TYPE_DEVICE_MEMORY_EXT = 8
M.VK_DEBUG_REPORT_OBJECT_TYPE_BUFFER_EXT = 9
M.VK_DEBUG_REPORT_OBJECT_TYPE_IMAGE_EXT = 10
M.VK_DEBUG_REPORT_OBJECT_TYPE_EVENT_EXT = 11
M.VK_DEBUG_REPORT_OBJECT_TYPE_QUERY_POOL_EXT = 12
M.VK_DEBUG_REPORT_OBJECT_TYPE_BUFFER_VIEW_EXT = 13
M.VK_DEBUG_REPORT_OBJECT_TYPE_IMAGE_VIEW_EXT = 14
M.VK_DEBUG_REPORT_OBJECT_TYPE_SHADER_MODULE_EXT = 15
M.VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_CACHE_EXT = 16
M.VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_LAYOUT_EXT = 17
M.VK_DEBUG_REPORT_OBJECT_TYPE_RENDER_PASS_EXT = 18
M.VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_EXT = 19
M.VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT_EXT = 20
M.VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_EXT = 21
M.VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_POOL_EXT = 22
M.VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_SET_EXT = 23
M.VK_DEBUG_REPORT_OBJECT_TYPE_FRAMEBUFFER_EXT = 24
M.VK_DEBUG_REPORT_OBJECT_TYPE_COMMAND_POOL_EXT = 25
M.VK_DEBUG_REPORT_OBJECT_TYPE_SURFACE_KHR_EXT = 26
M.VK_DEBUG_REPORT_OBJECT_TYPE_SWAPCHAIN_KHR_EXT = 27
M.VK_DEBUG_REPORT_OBJECT_TYPE_DEBUG_REPORT_CALLBACK_EXT_EXT = 28
M.VK_DEBUG_REPORT_OBJECT_TYPE_DISPLAY_KHR_EXT = 29
M.VK_DEBUG_REPORT_OBJECT_TYPE_DISPLAY_MODE_KHR_EXT = 30
M.VK_DEBUG_REPORT_OBJECT_TYPE_VALIDATION_CACHE_EXT_EXT = 33
M.VK_DEVICE_MEMORY_REPORT_EVENT_TYPE_ALLOCATE_EXT = 0
M.VK_DEVICE_MEMORY_REPORT_EVENT_TYPE_FREE_EXT = 1
M.VK_DEVICE_MEMORY_REPORT_EVENT_TYPE_IMPORT_EXT = 2
M.VK_DEVICE_MEMORY_REPORT_EVENT_TYPE_UNIMPORT_EXT = 3
M.VK_DEVICE_MEMORY_REPORT_EVENT_TYPE_ALLOCATION_FAILED_EXT = 4
M.VK_RASTERIZATION_ORDER_STRICT_AMD = 0
M.VK_RASTERIZATION_ORDER_RELAXED_AMD = 1
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_NV = 1
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_NV = 2
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_IMAGE_BIT_NV = 4
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_IMAGE_KMT_BIT_NV = 8
M.VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT_NV = 1
M.VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT_NV = 2
M.VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT_NV = 4
M.VK_CLUSTER_ACCELERATION_STRUCTURE_INDEX_FORMAT_8BIT_NV = 1
M.VK_CLUSTER_ACCELERATION_STRUCTURE_INDEX_FORMAT_16BIT_NV = 2
M.VK_CLUSTER_ACCELERATION_STRUCTURE_INDEX_FORMAT_32BIT_NV = 4
M.VK_CLUSTER_ACCELERATION_STRUCTURE_TYPE_CLUSTERS_BOTTOM_LEVEL_NV = 0
M.VK_CLUSTER_ACCELERATION_STRUCTURE_TYPE_TRIANGLE_CLUSTER_NV = 1
M.VK_CLUSTER_ACCELERATION_STRUCTURE_TYPE_TRIANGLE_CLUSTER_TEMPLATE_NV = 2
M.VK_CLUSTER_ACCELERATION_STRUCTURE_OP_TYPE_MOVE_OBJECTS_NV = 0
M.VK_CLUSTER_ACCELERATION_STRUCTURE_OP_TYPE_BUILD_CLUSTERS_BOTTOM_LEVEL_NV = 1
M.VK_CLUSTER_ACCELERATION_STRUCTURE_OP_TYPE_BUILD_TRIANGLE_CLUSTER_NV = 2
M.VK_CLUSTER_ACCELERATION_STRUCTURE_OP_TYPE_BUILD_TRIANGLE_CLUSTER_TEMPLATE_NV = 3
M.VK_CLUSTER_ACCELERATION_STRUCTURE_OP_TYPE_INSTANTIATE_TRIANGLE_CLUSTER_NV = 4
M.VK_CLUSTER_ACCELERATION_STRUCTURE_OP_TYPE_GET_CLUSTER_TEMPLATE_INDICES_NV = 5
M.VK_CLUSTER_ACCELERATION_STRUCTURE_OP_MODE_IMPLICIT_DESTINATIONS_NV = 0
M.VK_CLUSTER_ACCELERATION_STRUCTURE_OP_MODE_EXPLICIT_DESTINATIONS_NV = 1
M.VK_CLUSTER_ACCELERATION_STRUCTURE_OP_MODE_COMPUTE_SIZES_NV = 2
M.VK_CLUSTER_ACCELERATION_STRUCTURE_CLUSTER_ALLOW_DISABLE_OPACITY_MICROMAPS_NV = 1
M.VK_CLUSTER_ACCELERATION_STRUCTURE_GEOMETRY_CULL_DISABLE_BIT_NV = 1
M.VK_CLUSTER_ACCELERATION_STRUCTURE_GEOMETRY_NO_DUPLICATE_ANYHIT_INVOCATION_BIT_NV = 2
M.VK_CLUSTER_ACCELERATION_STRUCTURE_GEOMETRY_OPAQUE_BIT_NV = 4
M.VK_CLUSTER_ACCELERATION_STRUCTURE_ADDRESS_RESOLUTION_NONE_NV = 0
M.VK_CLUSTER_ACCELERATION_STRUCTURE_ADDRESS_RESOLUTION_INDIRECTED_DST_IMPLICIT_DATA_BIT_NV = 1
M.VK_CLUSTER_ACCELERATION_STRUCTURE_ADDRESS_RESOLUTION_INDIRECTED_SCRATCH_DATA_BIT_NV = 2
M.VK_CLUSTER_ACCELERATION_STRUCTURE_ADDRESS_RESOLUTION_INDIRECTED_DST_ADDRESS_ARRAY_BIT_NV = 4
M.VK_CLUSTER_ACCELERATION_STRUCTURE_ADDRESS_RESOLUTION_INDIRECTED_DST_SIZES_ARRAY_BIT_NV = 8
M.VK_CLUSTER_ACCELERATION_STRUCTURE_ADDRESS_RESOLUTION_INDIRECTED_SRC_INFOS_ARRAY_BIT_NV = 16
M.VK_CLUSTER_ACCELERATION_STRUCTURE_ADDRESS_RESOLUTION_INDIRECTED_SRC_INFOS_COUNT_BIT_NV = 32
M.VK_VALIDATION_CHECK_ALL_EXT = 0
M.VK_VALIDATION_CHECK_SHADERS_EXT = 1
M.VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_EXT = 0
M.VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_RESERVE_BINDING_SLOT_EXT = 1
M.VK_VALIDATION_FEATURE_ENABLE_BEST_PRACTICES_EXT = 2
M.VK_VALIDATION_FEATURE_ENABLE_DEBUG_PRINTF_EXT = 3
M.VK_VALIDATION_FEATURE_ENABLE_SYNCHRONIZATION_VALIDATION_EXT = 4
M.VK_VALIDATION_FEATURE_DISABLE_ALL_EXT = 0
M.VK_VALIDATION_FEATURE_DISABLE_SHADERS_EXT = 1
M.VK_VALIDATION_FEATURE_DISABLE_THREAD_SAFETY_EXT = 2
M.VK_VALIDATION_FEATURE_DISABLE_API_PARAMETERS_EXT = 3
M.VK_VALIDATION_FEATURE_DISABLE_OBJECT_LIFETIMES_EXT = 4
M.VK_VALIDATION_FEATURE_DISABLE_CORE_CHECKS_EXT = 5
M.VK_VALIDATION_FEATURE_DISABLE_UNIQUE_HANDLES_EXT = 6
M.VK_VALIDATION_FEATURE_DISABLE_SHADER_VALIDATION_CACHE_EXT = 7
M.VK_LAYER_SETTING_TYPE_BOOL32_EXT = 0
M.VK_LAYER_SETTING_TYPE_INT32_EXT = 1
M.VK_LAYER_SETTING_TYPE_INT64_EXT = 2
M.VK_LAYER_SETTING_TYPE_UINT32_EXT = 3
M.VK_LAYER_SETTING_TYPE_UINT64_EXT = 4
M.VK_LAYER_SETTING_TYPE_FLOAT32_EXT = 5
M.VK_LAYER_SETTING_TYPE_FLOAT64_EXT = 6
M.VK_LAYER_SETTING_TYPE_STRING_EXT = 7
M.VK_SUBGROUP_FEATURE_BASIC_BIT = 1
M.VK_SUBGROUP_FEATURE_VOTE_BIT = 2
M.VK_SUBGROUP_FEATURE_ARITHMETIC_BIT = 4
M.VK_SUBGROUP_FEATURE_BALLOT_BIT = 8
M.VK_SUBGROUP_FEATURE_SHUFFLE_BIT = 16
M.VK_SUBGROUP_FEATURE_SHUFFLE_RELATIVE_BIT = 32
M.VK_SUBGROUP_FEATURE_CLUSTERED_BIT = 64
M.VK_SUBGROUP_FEATURE_QUAD_BIT = 128
M.VK_INDIRECT_COMMANDS_LAYOUT_USAGE_EXPLICIT_PREPROCESS_BIT_NV = 1
M.VK_INDIRECT_COMMANDS_LAYOUT_USAGE_INDEXED_SEQUENCES_BIT_NV = 2
M.VK_INDIRECT_COMMANDS_LAYOUT_USAGE_UNORDERED_SEQUENCES_BIT_NV = 4
M.VK_INDIRECT_STATE_FLAG_FRONTFACE_BIT_NV = 1
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_SHADER_GROUP_NV = 0
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_STATE_FLAGS_NV = 1
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_INDEX_BUFFER_NV = 2
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_VERTEX_BUFFER_NV = 3
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_PUSH_CONSTANT_NV = 4
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_INDEXED_NV = 5
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_NV = 6
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_TASKS_NV = 7
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT = 1
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT = 2
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT = 4
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT = 8
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_KMT_BIT = 16
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_HEAP_BIT = 32
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT = 64
M.VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT = 1
M.VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT = 2
M.VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT = 4
M.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT = 1
M.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT = 2
M.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT = 4
M.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE_BIT = 8
M.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_SYNC_FD_BIT = 16
M.VK_EXTERNAL_SEMAPHORE_FEATURE_EXPORTABLE_BIT = 1
M.VK_EXTERNAL_SEMAPHORE_FEATURE_IMPORTABLE_BIT = 2
M.VK_SEMAPHORE_IMPORT_TEMPORARY_BIT = 1
M.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT = 1
M.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT = 2
M.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT = 4
M.VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT = 8
M.VK_EXTERNAL_FENCE_FEATURE_EXPORTABLE_BIT = 1
M.VK_EXTERNAL_FENCE_FEATURE_IMPORTABLE_BIT = 2
M.VK_FENCE_IMPORT_TEMPORARY_BIT = 1
M.VK_SURFACE_COUNTER_VBLANK_BIT_EXT = 1
M.VK_DISPLAY_POWER_STATE_OFF_EXT = 0
M.VK_DISPLAY_POWER_STATE_SUSPEND_EXT = 1
M.VK_DISPLAY_POWER_STATE_ON_EXT = 2
M.VK_DEVICE_EVENT_TYPE_DISPLAY_HOTPLUG_EXT = 0
M.VK_DISPLAY_EVENT_TYPE_FIRST_PIXEL_OUT_EXT = 0
M.VK_PEER_MEMORY_FEATURE_COPY_SRC_BIT = 1
M.VK_PEER_MEMORY_FEATURE_COPY_DST_BIT = 2
M.VK_PEER_MEMORY_FEATURE_GENERIC_SRC_BIT = 4
M.VK_PEER_MEMORY_FEATURE_GENERIC_DST_BIT = 8
M.VK_MEMORY_ALLOCATE_DEVICE_MASK_BIT = 1
M.VK_DEVICE_GROUP_PRESENT_MODE_LOCAL_BIT_KHR = 1
M.VK_DEVICE_GROUP_PRESENT_MODE_REMOTE_BIT_KHR = 2
M.VK_DEVICE_GROUP_PRESENT_MODE_SUM_BIT_KHR = 4
M.VK_DEVICE_GROUP_PRESENT_MODE_LOCAL_MULTI_DEVICE_BIT_KHR = 8
M.VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_X_NV = 0
M.VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_X_NV = 1
M.VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_Y_NV = 2
M.VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_Y_NV = 3
M.VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_Z_NV = 4
M.VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_Z_NV = 5
M.VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_W_NV = 6
M.VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_W_NV = 7
M.VK_DISCARD_RECTANGLE_MODE_INCLUSIVE_EXT = 0
M.VK_DISCARD_RECTANGLE_MODE_EXCLUSIVE_EXT = 1
M.VK_POINT_CLIPPING_BEHAVIOR_ALL_CLIP_PLANES = 0
M.VK_POINT_CLIPPING_BEHAVIOR_USER_CLIP_PLANES_ONLY = 1
M.VK_SAMPLER_REDUCTION_MODE_WEIGHTED_AVERAGE = 0
M.VK_SAMPLER_REDUCTION_MODE_MIN = 1
M.VK_SAMPLER_REDUCTION_MODE_MAX = 2
M.VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT = 0
M.VK_TESSELLATION_DOMAIN_ORIGIN_LOWER_LEFT = 1
M.VK_SAMPLER_YCBCR_MODEL_CONVERSION_RGB_IDENTITY = 0
M.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_IDENTITY = 1
M.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_709 = 2
M.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_601 = 3
M.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_2020 = 4
M.VK_SAMPLER_YCBCR_RANGE_ITU_FULL = 0
M.VK_SAMPLER_YCBCR_RANGE_ITU_NARROW = 1
M.VK_CHROMA_LOCATION_COSITED_EVEN = 0
M.VK_CHROMA_LOCATION_MIDPOINT = 1
M.VK_BLEND_OVERLAP_UNCORRELATED_EXT = 0
M.VK_BLEND_OVERLAP_DISJOINT_EXT = 1
M.VK_BLEND_OVERLAP_CONJOINT_EXT = 2
M.VK_COVERAGE_MODULATION_MODE_NONE_NV = 0
M.VK_COVERAGE_MODULATION_MODE_RGB_NV = 1
M.VK_COVERAGE_MODULATION_MODE_ALPHA_NV = 2
M.VK_COVERAGE_MODULATION_MODE_RGBA_NV = 3
M.VK_COVERAGE_REDUCTION_MODE_MERGE_NV = 0
M.VK_COVERAGE_REDUCTION_MODE_TRUNCATE_NV = 1
M.VK_VALIDATION_CACHE_HEADER_VERSION_ONE_EXT = 1
M.VK_SHADER_INFO_TYPE_STATISTICS_AMD = 0
M.VK_SHADER_INFO_TYPE_BINARY_AMD = 1
M.VK_SHADER_INFO_TYPE_DISASSEMBLY_AMD = 2
M.VK_QUEUE_GLOBAL_PRIORITY_LOW = 128
M.VK_QUEUE_GLOBAL_PRIORITY_MEDIUM = 256
M.VK_QUEUE_GLOBAL_PRIORITY_HIGH = 512
M.VK_QUEUE_GLOBAL_PRIORITY_REALTIME = 1024
M.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT = 1
M.VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT = 16
M.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT = 256
M.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT = 4096
M.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT = 1
M.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT = 2
M.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT = 4
M.VK_CONSERVATIVE_RASTERIZATION_MODE_DISABLED_EXT = 0
M.VK_CONSERVATIVE_RASTERIZATION_MODE_OVERESTIMATE_EXT = 1
M.VK_CONSERVATIVE_RASTERIZATION_MODE_UNDERESTIMATE_EXT = 2
M.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT = 1
M.VK_DESCRIPTOR_BINDING_UPDATE_UNUSED_WHILE_PENDING_BIT = 2
M.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT = 4
M.VK_DESCRIPTOR_BINDING_VARIABLE_DESCRIPTOR_COUNT_BIT = 8
M.VK_VENDOR_ID_KHRONOS = 0x10000
M.VK_VENDOR_ID_VIV = 0x10001
M.VK_VENDOR_ID_VSI = 0x10002
M.VK_VENDOR_ID_KAZAN = 0x10003
M.VK_VENDOR_ID_CODEPLAY = 0x10004
M.VK_VENDOR_ID_MESA = 0x10005
M.VK_VENDOR_ID_POCL = 0x10006
M.VK_VENDOR_ID_MOBILEYE = 0x10007
M.VK_DRIVER_ID_AMD_PROPRIETARY = 1
M.VK_DRIVER_ID_AMD_OPEN_SOURCE = 2
M.VK_DRIVER_ID_MESA_RADV = 3
M.VK_DRIVER_ID_NVIDIA_PROPRIETARY = 4
M.VK_DRIVER_ID_INTEL_PROPRIETARY_WINDOWS = 5
M.VK_DRIVER_ID_INTEL_OPEN_SOURCE_MESA = 6
M.VK_DRIVER_ID_IMAGINATION_PROPRIETARY = 7
M.VK_DRIVER_ID_QUALCOMM_PROPRIETARY = 8
M.VK_DRIVER_ID_ARM_PROPRIETARY = 9
M.VK_DRIVER_ID_GOOGLE_SWIFTSHADER = 10
M.VK_DRIVER_ID_GGP_PROPRIETARY = 11
M.VK_DRIVER_ID_BROADCOM_PROPRIETARY = 12
M.VK_DRIVER_ID_MESA_LLVMPIPE = 13
M.VK_DRIVER_ID_MOLTENVK = 14
M.VK_DRIVER_ID_COREAVI_PROPRIETARY = 15
M.VK_DRIVER_ID_JUICE_PROPRIETARY = 16
M.VK_DRIVER_ID_VERISILICON_PROPRIETARY = 17
M.VK_DRIVER_ID_MESA_TURNIP = 18
M.VK_DRIVER_ID_MESA_V3DV = 19
M.VK_DRIVER_ID_MESA_PANVK = 20
M.VK_DRIVER_ID_SAMSUNG_PROPRIETARY = 21
M.VK_DRIVER_ID_MESA_VENUS = 22
M.VK_DRIVER_ID_MESA_DOZEN = 23
M.VK_DRIVER_ID_MESA_NVK = 24
M.VK_DRIVER_ID_IMAGINATION_OPEN_SOURCE_MESA = 25
M.VK_DRIVER_ID_MESA_HONEYKRISP = 26
M.VK_DRIVER_ID_VULKAN_SC_EMULATION_ON_VULKAN = 27
M.VK_DRIVER_ID_MESA_KOSMICKRISP = 28
M.VK_CONDITIONAL_RENDERING_INVERTED_BIT_EXT = 1
M.VK_RESOLVE_MODE_NONE = 0
M.VK_RESOLVE_MODE_SAMPLE_ZERO_BIT = 1
M.VK_RESOLVE_MODE_AVERAGE_BIT = 2
M.VK_RESOLVE_MODE_MIN_BIT = 4
M.VK_RESOLVE_MODE_MAX_BIT = 8
M.VK_SHADING_RATE_PALETTE_ENTRY_NO_INVOCATIONS_NV = 0
M.VK_SHADING_RATE_PALETTE_ENTRY_16_INVOCATIONS_PER_PIXEL_NV = 1
M.VK_SHADING_RATE_PALETTE_ENTRY_8_INVOCATIONS_PER_PIXEL_NV = 2
M.VK_SHADING_RATE_PALETTE_ENTRY_4_INVOCATIONS_PER_PIXEL_NV = 3
M.VK_SHADING_RATE_PALETTE_ENTRY_2_INVOCATIONS_PER_PIXEL_NV = 4
M.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_PIXEL_NV = 5
M.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X1_PIXELS_NV = 6
M.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_1X2_PIXELS_NV = 7
M.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X2_PIXELS_NV = 8
M.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_4X2_PIXELS_NV = 9
M.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X4_PIXELS_NV = 10
M.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_4X4_PIXELS_NV = 11
M.VK_COARSE_SAMPLE_ORDER_TYPE_DEFAULT_NV = 0
M.VK_COARSE_SAMPLE_ORDER_TYPE_CUSTOM_NV = 1
M.VK_COARSE_SAMPLE_ORDER_TYPE_PIXEL_MAJOR_NV = 2
M.VK_COARSE_SAMPLE_ORDER_TYPE_SAMPLE_MAJOR_NV = 3
M.VK_GEOMETRY_INSTANCE_TRIANGLE_FACING_CULL_DISABLE_BIT_KHR = 1
M.VK_GEOMETRY_INSTANCE_TRIANGLE_FLIP_FACING_BIT_KHR = 2
M.VK_GEOMETRY_INSTANCE_FORCE_OPAQUE_BIT_KHR = 4
M.VK_GEOMETRY_INSTANCE_FORCE_NO_OPAQUE_BIT_KHR = 8
M.VK_GEOMETRY_OPAQUE_BIT_KHR = 1
M.VK_GEOMETRY_NO_DUPLICATE_ANY_HIT_INVOCATION_BIT_KHR = 2
M.VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_UPDATE_BIT_KHR = 1
M.VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_COMPACTION_BIT_KHR = 2
M.VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR = 4
M.VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_BUILD_BIT_KHR = 8
M.VK_BUILD_ACCELERATION_STRUCTURE_LOW_MEMORY_BIT_KHR = 16
M.VK_ACCELERATION_STRUCTURE_CREATE_DEVICE_ADDRESS_CAPTURE_REPLAY_BIT_KHR = 1
M.VK_COPY_ACCELERATION_STRUCTURE_MODE_CLONE_KHR = 0
M.VK_COPY_ACCELERATION_STRUCTURE_MODE_COMPACT_KHR = 1
M.VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR = 0
M.VK_BUILD_ACCELERATION_STRUCTURE_MODE_UPDATE_KHR = 1
M.VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR = 0
M.VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR = 1
M.VK_ACCELERATION_STRUCTURE_TYPE_GENERIC_KHR = 2
M.VK_GEOMETRY_TYPE_TRIANGLES_KHR = 0
M.VK_GEOMETRY_TYPE_AABBS_KHR = 1
M.VK_GEOMETRY_TYPE_INSTANCES_KHR = 2
M.VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_OBJECT_NV = 0
M.VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_BUILD_SCRATCH_NV = 1
M.VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_UPDATE_SCRATCH_NV = 2
M.VK_ACCELERATION_STRUCTURE_BUILD_TYPE_HOST_KHR = 0
M.VK_ACCELERATION_STRUCTURE_BUILD_TYPE_DEVICE_KHR = 1
M.VK_ACCELERATION_STRUCTURE_BUILD_TYPE_HOST_OR_DEVICE_KHR = 2
M.VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_KHR = 0
M.VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_KHR = 1
M.VK_RAY_TRACING_SHADER_GROUP_TYPE_PROCEDURAL_HIT_GROUP_KHR = 2
M.VK_ACCELERATION_STRUCTURE_COMPATIBILITY_COMPATIBLE_KHR = 0
M.VK_ACCELERATION_STRUCTURE_COMPATIBILITY_INCOMPATIBLE_KHR = 1
M.VK_SHADER_GROUP_SHADER_GENERAL_KHR = 0
M.VK_SHADER_GROUP_SHADER_CLOSEST_HIT_KHR = 1
M.VK_SHADER_GROUP_SHADER_ANY_HIT_KHR = 2
M.VK_SHADER_GROUP_SHADER_INTERSECTION_KHR = 3
M.VK_MEMORY_OVERALLOCATION_BEHAVIOR_DEFAULT_AMD = 0
M.VK_MEMORY_OVERALLOCATION_BEHAVIOR_ALLOWED_AMD = 1
M.VK_MEMORY_OVERALLOCATION_BEHAVIOR_DISALLOWED_AMD = 2
M.VK_DEVICE_DIAGNOSTICS_CONFIG_ENABLE_SHADER_DEBUG_INFO_BIT_NV = 1
M.VK_DEVICE_DIAGNOSTICS_CONFIG_ENABLE_RESOURCE_TRACKING_BIT_NV = 2
M.VK_DEVICE_DIAGNOSTICS_CONFIG_ENABLE_AUTOMATIC_CHECKPOINTS_BIT_NV = 4
M.VK_DEVICE_DIAGNOSTICS_CONFIG_ENABLE_SHADER_ERROR_REPORTING_BIT_NV = 8
M.VK_PIPELINE_CREATION_FEEDBACK_VALID_BIT = 1
M.VK_PIPELINE_CREATION_FEEDBACK_APPLICATION_PIPELINE_CACHE_HIT_BIT = 2
M.VK_PIPELINE_CREATION_FEEDBACK_BASE_PIPELINE_ACCELERATION_BIT = 4
M.VK_FULL_SCREEN_EXCLUSIVE_DEFAULT_EXT = 0
M.VK_FULL_SCREEN_EXCLUSIVE_ALLOWED_EXT = 1
M.VK_FULL_SCREEN_EXCLUSIVE_DISALLOWED_EXT = 2
M.VK_FULL_SCREEN_EXCLUSIVE_APPLICATION_CONTROLLED_EXT = 3
M.VK_PERFORMANCE_COUNTER_SCOPE_COMMAND_BUFFER_KHR = 0
M.VK_PERFORMANCE_COUNTER_SCOPE_RENDER_PASS_KHR = 1
M.VK_PERFORMANCE_COUNTER_SCOPE_COMMAND_KHR = 2
M.VK_MEMORY_DECOMPRESSION_METHOD_GDEFLATE_1_0_BIT_EXT = 1
M.VK_PERFORMANCE_COUNTER_UNIT_GENERIC_KHR = 0
M.VK_PERFORMANCE_COUNTER_UNIT_PERCENTAGE_KHR = 1
M.VK_PERFORMANCE_COUNTER_UNIT_NANOSECONDS_KHR = 2
M.VK_PERFORMANCE_COUNTER_UNIT_BYTES_KHR = 3
M.VK_PERFORMANCE_COUNTER_UNIT_BYTES_PER_SECOND_KHR = 4
M.VK_PERFORMANCE_COUNTER_UNIT_KELVIN_KHR = 5
M.VK_PERFORMANCE_COUNTER_UNIT_WATTS_KHR = 6
M.VK_PERFORMANCE_COUNTER_UNIT_VOLTS_KHR = 7
M.VK_PERFORMANCE_COUNTER_UNIT_AMPS_KHR = 8
M.VK_PERFORMANCE_COUNTER_UNIT_HERTZ_KHR = 9
M.VK_PERFORMANCE_COUNTER_UNIT_CYCLES_KHR = 10
M.VK_PERFORMANCE_COUNTER_STORAGE_INT32_KHR = 0
M.VK_PERFORMANCE_COUNTER_STORAGE_INT64_KHR = 1
M.VK_PERFORMANCE_COUNTER_STORAGE_UINT32_KHR = 2
M.VK_PERFORMANCE_COUNTER_STORAGE_UINT64_KHR = 3
M.VK_PERFORMANCE_COUNTER_STORAGE_FLOAT32_KHR = 4
M.VK_PERFORMANCE_COUNTER_STORAGE_FLOAT64_KHR = 5
M.VK_PERFORMANCE_COUNTER_DESCRIPTION_PERFORMANCE_IMPACTING_BIT_KHR = 1
M.VK_PERFORMANCE_COUNTER_DESCRIPTION_CONCURRENTLY_IMPACTED_BIT_KHR = 2
M.VK_PERFORMANCE_CONFIGURATION_TYPE_COMMAND_QUEUE_METRICS_DISCOVERY_ACTIVATED_INTEL = 0
M.VK_QUERY_POOL_SAMPLING_MODE_MANUAL_INTEL = 0
M.VK_PERFORMANCE_OVERRIDE_TYPE_NULL_HARDWARE_INTEL = 0
M.VK_PERFORMANCE_OVERRIDE_TYPE_FLUSH_GPU_CACHES_INTEL = 1
M.VK_PERFORMANCE_PARAMETER_TYPE_HW_COUNTERS_SUPPORTED_INTEL = 0
M.VK_PERFORMANCE_PARAMETER_TYPE_STREAM_MARKER_VALID_BITS_INTEL = 1
M.VK_PERFORMANCE_VALUE_TYPE_UINT32_INTEL = 0
M.VK_PERFORMANCE_VALUE_TYPE_UINT64_INTEL = 1
M.VK_PERFORMANCE_VALUE_TYPE_FLOAT_INTEL = 2
M.VK_PERFORMANCE_VALUE_TYPE_BOOL_INTEL = 3
M.VK_PERFORMANCE_VALUE_TYPE_STRING_INTEL = 4
M.VK_SHADER_FLOAT_CONTROLS_INDEPENDENCE_32_BIT_ONLY = 0
M.VK_SHADER_FLOAT_CONTROLS_INDEPENDENCE_ALL = 1
M.VK_SHADER_FLOAT_CONTROLS_INDEPENDENCE_NONE = 2
M.VK_PIPELINE_EXECUTABLE_STATISTIC_FORMAT_BOOL32_KHR = 0
M.VK_PIPELINE_EXECUTABLE_STATISTIC_FORMAT_INT64_KHR = 1
M.VK_PIPELINE_EXECUTABLE_STATISTIC_FORMAT_UINT64_KHR = 2
M.VK_PIPELINE_EXECUTABLE_STATISTIC_FORMAT_FLOAT64_KHR = 3
M.VK_LINE_RASTERIZATION_MODE_DEFAULT = 0
M.VK_LINE_RASTERIZATION_MODE_RECTANGULAR = 1
M.VK_LINE_RASTERIZATION_MODE_BRESENHAM = 2
M.VK_LINE_RASTERIZATION_MODE_RECTANGULAR_SMOOTH = 3
M.VK_FAULT_LEVEL_UNASSIGNED = 0
M.VK_FAULT_LEVEL_CRITICAL = 1
M.VK_FAULT_LEVEL_RECOVERABLE = 2
M.VK_FAULT_LEVEL_WARNING = 3
M.VK_FAULT_TYPE_INVALID = 0
M.VK_FAULT_TYPE_UNASSIGNED = 1
M.VK_FAULT_TYPE_IMPLEMENTATION = 2
M.VK_FAULT_TYPE_SYSTEM = 3
M.VK_FAULT_TYPE_PHYSICAL_DEVICE = 4
M.VK_FAULT_TYPE_COMMAND_BUFFER_FULL = 5
M.VK_FAULT_TYPE_INVALID_API_USAGE = 6
M.VK_FAULT_QUERY_BEHAVIOR_GET_AND_CLEAR_ALL_FAULTS = 0
M.VK_TOOL_PURPOSE_VALIDATION_BIT = 1
M.VK_TOOL_PURPOSE_PROFILING_BIT = 2
M.VK_TOOL_PURPOSE_TRACING_BIT = 4
M.VK_TOOL_PURPOSE_ADDITIONAL_FEATURES_BIT = 8
M.VK_TOOL_PURPOSE_MODIFYING_FEATURES_BIT = 16
M.VK_PIPELINE_MATCH_CONTROL_APPLICATION_UUID_EXACT_MATCH = 0
M.VK_FRAGMENT_SHADING_RATE_COMBINER_OP_KEEP_KHR = 0
M.VK_FRAGMENT_SHADING_RATE_COMBINER_OP_REPLACE_KHR = 1
M.VK_FRAGMENT_SHADING_RATE_COMBINER_OP_MIN_KHR = 2
M.VK_FRAGMENT_SHADING_RATE_COMBINER_OP_MAX_KHR = 3
M.VK_FRAGMENT_SHADING_RATE_COMBINER_OP_MUL_KHR = 4
M.VK_FRAGMENT_SHADING_RATE_1_INVOCATION_PER_PIXEL_NV = 0
M.VK_FRAGMENT_SHADING_RATE_1_INVOCATION_PER_1X2_PIXELS_NV = 1
M.VK_FRAGMENT_SHADING_RATE_1_INVOCATION_PER_2X1_PIXELS_NV = 4
M.VK_FRAGMENT_SHADING_RATE_1_INVOCATION_PER_2X2_PIXELS_NV = 5
M.VK_FRAGMENT_SHADING_RATE_1_INVOCATION_PER_2X4_PIXELS_NV = 6
M.VK_FRAGMENT_SHADING_RATE_1_INVOCATION_PER_4X2_PIXELS_NV = 9
M.VK_FRAGMENT_SHADING_RATE_1_INVOCATION_PER_4X4_PIXELS_NV = 10
M.VK_FRAGMENT_SHADING_RATE_2_INVOCATIONS_PER_PIXEL_NV = 11
M.VK_FRAGMENT_SHADING_RATE_4_INVOCATIONS_PER_PIXEL_NV = 12
M.VK_FRAGMENT_SHADING_RATE_8_INVOCATIONS_PER_PIXEL_NV = 13
M.VK_FRAGMENT_SHADING_RATE_16_INVOCATIONS_PER_PIXEL_NV = 14
M.VK_FRAGMENT_SHADING_RATE_NO_INVOCATIONS_NV = 15
M.VK_FRAGMENT_SHADING_RATE_TYPE_FRAGMENT_SIZE_NV = 0
M.VK_FRAGMENT_SHADING_RATE_TYPE_ENUMS_NV = 1
M.VK_SUBPASS_MERGE_STATUS_MERGED_EXT = 0
M.VK_SUBPASS_MERGE_STATUS_DISALLOWED_EXT = 1
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_SIDE_EFFECTS_EXT = 2
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_SAMPLES_MISMATCH_EXT = 3
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_VIEWS_MISMATCH_EXT = 4
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_ALIASING_EXT = 5
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_DEPENDENCIES_EXT = 6
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_INCOMPATIBLE_INPUT_ATTACHMENT_EXT = 7
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_TOO_MANY_ATTACHMENTS_EXT = 8
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_INSUFFICIENT_STORAGE_EXT = 9
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_DEPTH_STENCIL_COUNT_EXT = 10
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_RESOLVE_ATTACHMENT_REUSE_EXT = 11
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_SINGLE_SUBPASS_EXT = 12
M.VK_SUBPASS_MERGE_STATUS_NOT_MERGED_UNSPECIFIED_EXT = 13
M.VK_ACCESS_2_NONE = 0
M.VK_ACCESS_2_INDIRECT_COMMAND_READ_BIT = 1
M.VK_ACCESS_2_INDEX_READ_BIT = 2
M.VK_ACCESS_2_VERTEX_ATTRIBUTE_READ_BIT = 4
M.VK_ACCESS_2_UNIFORM_READ_BIT = 8
M.VK_ACCESS_2_INPUT_ATTACHMENT_READ_BIT = 16
M.VK_ACCESS_2_SHADER_READ_BIT = 32
M.VK_ACCESS_2_SHADER_WRITE_BIT = 64
M.VK_ACCESS_2_COLOR_ATTACHMENT_READ_BIT = 128
M.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT = 256
M.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_READ_BIT = 512
M.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT = 1024
M.VK_ACCESS_2_TRANSFER_READ_BIT = 2048
M.VK_ACCESS_2_TRANSFER_WRITE_BIT = 4096
M.VK_ACCESS_2_HOST_READ_BIT = 8192
M.VK_ACCESS_2_HOST_WRITE_BIT = 16384
M.VK_ACCESS_2_MEMORY_READ_BIT = 32768
M.VK_ACCESS_2_MEMORY_WRITE_BIT = 65536
M.VK_ACCESS_2_SHADER_SAMPLED_READ_BIT = 4294967296
M.VK_ACCESS_2_SHADER_STORAGE_READ_BIT = 8589934592
M.VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT = 17179869184
M.VK_PIPELINE_STAGE_2_NONE = 0
M.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT = 1
M.VK_PIPELINE_STAGE_2_DRAW_INDIRECT_BIT = 2
M.VK_PIPELINE_STAGE_2_VERTEX_INPUT_BIT = 4
M.VK_PIPELINE_STAGE_2_VERTEX_SHADER_BIT = 8
M.VK_PIPELINE_STAGE_2_TESSELLATION_CONTROL_SHADER_BIT = 16
M.VK_PIPELINE_STAGE_2_TESSELLATION_EVALUATION_SHADER_BIT = 32
M.VK_PIPELINE_STAGE_2_GEOMETRY_SHADER_BIT = 64
M.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT = 128
M.VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT = 256
M.VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT = 512
M.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT = 1024
M.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT = 2048
M.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT = 4096
M.VK_PIPELINE_STAGE_2_BOTTOM_OF_PIPE_BIT = 8192
M.VK_PIPELINE_STAGE_2_HOST_BIT = 16384
M.VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT = 32768
M.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT = 65536
M.VK_PIPELINE_STAGE_2_COPY_BIT = 4294967296
M.VK_PIPELINE_STAGE_2_RESOLVE_BIT = 8589934592
M.VK_PIPELINE_STAGE_2_BLIT_BIT = 17179869184
M.VK_PIPELINE_STAGE_2_CLEAR_BIT = 34359738368
M.VK_PIPELINE_STAGE_2_INDEX_INPUT_BIT = 68719476736
M.VK_PIPELINE_STAGE_2_VERTEX_ATTRIBUTE_INPUT_BIT = 137438953472
M.VK_PIPELINE_STAGE_2_PRE_RASTERIZATION_SHADERS_BIT = 274877906944
M.VK_SUBMIT_PROTECTED_BIT = 1
M.VK_SCI_SYNC_CLIENT_TYPE_SIGNALER_NV = 0
M.VK_SCI_SYNC_CLIENT_TYPE_WAITER_NV = 1
M.VK_SCI_SYNC_CLIENT_TYPE_SIGNALER_WAITER_NV = 2
M.VK_SCI_SYNC_PRIMITIVE_TYPE_FENCE_NV = 0
M.VK_SCI_SYNC_PRIMITIVE_TYPE_SEMAPHORE_NV = 1
M.VK_PROVOKING_VERTEX_MODE_FIRST_VERTEX_EXT = 0
M.VK_PROVOKING_VERTEX_MODE_LAST_VERTEX_EXT = 1
M.VK_PIPELINE_CACHE_VALIDATION_VERSION_SAFETY_CRITICAL_ONE = 1
M.VK_ACCELERATION_STRUCTURE_MOTION_INSTANCE_TYPE_STATIC_NV = 0
M.VK_ACCELERATION_STRUCTURE_MOTION_INSTANCE_TYPE_MATRIX_MOTION_NV = 1
M.VK_ACCELERATION_STRUCTURE_MOTION_INSTANCE_TYPE_SRT_MOTION_NV = 2
M.VK_GRAPHICS_PIPELINE_LIBRARY_VERTEX_INPUT_INTERFACE_BIT_EXT = 1
M.VK_GRAPHICS_PIPELINE_LIBRARY_PRE_RASTERIZATION_SHADERS_BIT_EXT = 2
M.VK_GRAPHICS_PIPELINE_LIBRARY_FRAGMENT_SHADER_BIT_EXT = 4
M.VK_GRAPHICS_PIPELINE_LIBRARY_FRAGMENT_OUTPUT_INTERFACE_BIT_EXT = 8
M.VK_DEVICE_ADDRESS_BINDING_INTERNAL_OBJECT_BIT_EXT = 1
M.VK_DEVICE_ADDRESS_BINDING_TYPE_BIND_EXT = 0
M.VK_DEVICE_ADDRESS_BINDING_TYPE_UNBIND_EXT = 1
M.VK_FRAME_BOUNDARY_FRAME_END_BIT_EXT = 1
M.VK_PRESENT_SCALING_ONE_TO_ONE_BIT_KHR = 1
M.VK_PRESENT_SCALING_ASPECT_RATIO_STRETCH_BIT_KHR = 2
M.VK_PRESENT_SCALING_STRETCH_BIT_KHR = 4
M.VK_PRESENT_GRAVITY_MIN_BIT_KHR = 1
M.VK_PRESENT_GRAVITY_MAX_BIT_KHR = 2
M.VK_PRESENT_GRAVITY_CENTERED_BIT_KHR = 4
M.VK_PHYSICAL_DEVICE_SCHEDULING_CONTROLS_SHADER_CORE_COUNT_ARM = 1
M.VK_PRESENT_STAGE_QUEUE_OPERATIONS_END_BIT_EXT = 1
M.VK_PRESENT_STAGE_REQUEST_DEQUEUED_BIT_EXT = 2
M.VK_PRESENT_STAGE_IMAGE_FIRST_PIXEL_OUT_BIT_EXT = 4
M.VK_PRESENT_STAGE_IMAGE_FIRST_PIXEL_VISIBLE_BIT_EXT = 8
M.VK_PAST_PRESENTATION_TIMING_ALLOW_PARTIAL_RESULTS_BIT_EXT = 1
M.VK_PAST_PRESENTATION_TIMING_ALLOW_OUT_OF_ORDER_RESULTS_BIT_EXT = 2
M.VK_PRESENT_TIMING_INFO_PRESENT_AT_RELATIVE_TIME_BIT_EXT = 1
M.VK_PRESENT_TIMING_INFO_PRESENT_AT_NEAREST_REFRESH_CYCLE_BIT_EXT = 2
M.VK_VIDEO_CODEC_OPERATION_NONE_KHR = 0
M.VK_VIDEO_CHROMA_SUBSAMPLING_INVALID_KHR = 0
M.VK_VIDEO_CHROMA_SUBSAMPLING_MONOCHROME_BIT_KHR = 1
M.VK_VIDEO_CHROMA_SUBSAMPLING_420_BIT_KHR = 2
M.VK_VIDEO_CHROMA_SUBSAMPLING_422_BIT_KHR = 4
M.VK_VIDEO_CHROMA_SUBSAMPLING_444_BIT_KHR = 8
M.VK_VIDEO_COMPONENT_BIT_DEPTH_INVALID_KHR = 0
M.VK_VIDEO_COMPONENT_BIT_DEPTH_8_BIT_KHR = 1
M.VK_VIDEO_COMPONENT_BIT_DEPTH_10_BIT_KHR = 4
M.VK_VIDEO_COMPONENT_BIT_DEPTH_12_BIT_KHR = 16
M.VK_VIDEO_CAPABILITY_PROTECTED_CONTENT_BIT_KHR = 1
M.VK_VIDEO_CAPABILITY_SEPARATE_REFERENCE_IMAGES_BIT_KHR = 2
M.VK_VIDEO_SESSION_CREATE_PROTECTED_CONTENT_BIT_KHR = 1
M.VK_VIDEO_DECODE_H264_PICTURE_LAYOUT_PROGRESSIVE_KHR = 0
M.VK_VIDEO_DECODE_H264_PICTURE_LAYOUT_INTERLACED_INTERLEAVED_LINES_BIT_KHR = 1
M.VK_VIDEO_DECODE_H264_PICTURE_LAYOUT_INTERLACED_SEPARATE_PLANES_BIT_KHR = 2
M.VK_VIDEO_CODING_CONTROL_RESET_BIT_KHR = 1
M.VK_QUERY_RESULT_STATUS_ERROR_KHR = -1
M.VK_QUERY_RESULT_STATUS_NOT_READY_KHR = 0
M.VK_QUERY_RESULT_STATUS_COMPLETE_KHR = 1
M.VK_VIDEO_DECODE_USAGE_DEFAULT_KHR = 0
M.VK_VIDEO_DECODE_USAGE_TRANSCODING_BIT_KHR = 1
M.VK_VIDEO_DECODE_USAGE_OFFLINE_BIT_KHR = 2
M.VK_VIDEO_DECODE_USAGE_STREAMING_BIT_KHR = 4
M.VK_VIDEO_DECODE_CAPABILITY_DPB_AND_OUTPUT_COINCIDE_BIT_KHR = 1
M.VK_VIDEO_DECODE_CAPABILITY_DPB_AND_OUTPUT_DISTINCT_BIT_KHR = 2
M.VK_VIDEO_ENCODE_USAGE_DEFAULT_KHR = 0
M.VK_VIDEO_ENCODE_USAGE_TRANSCODING_BIT_KHR = 1
M.VK_VIDEO_ENCODE_USAGE_STREAMING_BIT_KHR = 2
M.VK_VIDEO_ENCODE_USAGE_RECORDING_BIT_KHR = 4
M.VK_VIDEO_ENCODE_USAGE_CONFERENCING_BIT_KHR = 8
M.VK_VIDEO_ENCODE_CONTENT_DEFAULT_KHR = 0
M.VK_VIDEO_ENCODE_CONTENT_CAMERA_BIT_KHR = 1
M.VK_VIDEO_ENCODE_CONTENT_DESKTOP_BIT_KHR = 2
M.VK_VIDEO_ENCODE_CONTENT_RENDERED_BIT_KHR = 4
M.VK_VIDEO_ENCODE_TUNING_MODE_DEFAULT_KHR = 0
M.VK_VIDEO_ENCODE_TUNING_MODE_HIGH_QUALITY_KHR = 1
M.VK_VIDEO_ENCODE_TUNING_MODE_LOW_LATENCY_KHR = 2
M.VK_VIDEO_ENCODE_TUNING_MODE_ULTRA_LOW_LATENCY_KHR = 3
M.VK_VIDEO_ENCODE_TUNING_MODE_LOSSLESS_KHR = 4
M.VK_VIDEO_ENCODE_CAPABILITY_PRECEDING_EXTERNALLY_ENCODED_BYTES_BIT_KHR = 1
M.VK_VIDEO_ENCODE_CAPABILITY_INSUFFICIENT_BITSTREAM_BUFFER_RANGE_DETECTION_BIT_KHR = 2
M.VK_VIDEO_ENCODE_FEEDBACK_BITSTREAM_BUFFER_OFFSET_BIT_KHR = 1
M.VK_VIDEO_ENCODE_FEEDBACK_BITSTREAM_BYTES_WRITTEN_BIT_KHR = 2
M.VK_VIDEO_ENCODE_FEEDBACK_BITSTREAM_HAS_OVERRIDES_BIT_KHR = 4
M.VK_VIDEO_ENCODE_RATE_CONTROL_MODE_DEFAULT_KHR = 0
M.VK_VIDEO_ENCODE_RATE_CONTROL_MODE_DISABLED_BIT_KHR = 1
M.VK_VIDEO_ENCODE_RATE_CONTROL_MODE_CBR_BIT_KHR = 2
M.VK_VIDEO_ENCODE_RATE_CONTROL_MODE_VBR_BIT_KHR = 4
M.VK_VIDEO_ENCODE_INTRA_REFRESH_MODE_NONE_KHR = 0
M.VK_VIDEO_ENCODE_INTRA_REFRESH_MODE_PER_PICTURE_PARTITION_BIT_KHR = 1
M.VK_VIDEO_ENCODE_INTRA_REFRESH_MODE_BLOCK_BASED_BIT_KHR = 2
M.VK_VIDEO_ENCODE_INTRA_REFRESH_MODE_BLOCK_ROW_BASED_BIT_KHR = 4
M.VK_VIDEO_ENCODE_INTRA_REFRESH_MODE_BLOCK_COLUMN_BASED_BIT_KHR = 8
M.VK_VIDEO_ENCODE_H264_CAPABILITY_HRD_COMPLIANCE_BIT_KHR = 1
M.VK_VIDEO_ENCODE_H264_CAPABILITY_PREDICTION_WEIGHT_TABLE_GENERATED_BIT_KHR = 2
M.VK_VIDEO_ENCODE_H264_CAPABILITY_ROW_UNALIGNED_SLICE_BIT_KHR = 4
M.VK_VIDEO_ENCODE_H264_CAPABILITY_DIFFERENT_SLICE_TYPE_BIT_KHR = 8
M.VK_VIDEO_ENCODE_H264_CAPABILITY_B_FRAME_IN_L0_LIST_BIT_KHR = 16
M.VK_VIDEO_ENCODE_H264_CAPABILITY_B_FRAME_IN_L1_LIST_BIT_KHR = 32
M.VK_VIDEO_ENCODE_H264_CAPABILITY_PER_PICTURE_TYPE_MIN_MAX_QP_BIT_KHR = 64
M.VK_VIDEO_ENCODE_H264_CAPABILITY_PER_SLICE_CONSTANT_QP_BIT_KHR = 128
M.VK_VIDEO_ENCODE_H264_CAPABILITY_GENERATE_PREFIX_NALU_BIT_KHR = 256
M.VK_VIDEO_ENCODE_H264_STD_SEPARATE_COLOR_PLANE_FLAG_SET_BIT_KHR = 1
M.VK_VIDEO_ENCODE_H264_STD_QPPRIME_Y_ZERO_TRANSFORM_BYPASS_FLAG_SET_BIT_KHR = 2
M.VK_VIDEO_ENCODE_H264_STD_SCALING_MATRIX_PRESENT_FLAG_SET_BIT_KHR = 4
M.VK_VIDEO_ENCODE_H264_STD_CHROMA_QP_INDEX_OFFSET_BIT_KHR = 8
M.VK_VIDEO_ENCODE_H264_STD_SECOND_CHROMA_QP_INDEX_OFFSET_BIT_KHR = 16
M.VK_VIDEO_ENCODE_H264_STD_PIC_INIT_QP_MINUS26_BIT_KHR = 32
M.VK_VIDEO_ENCODE_H264_STD_WEIGHTED_PRED_FLAG_SET_BIT_KHR = 64
M.VK_VIDEO_ENCODE_H264_STD_WEIGHTED_BIPRED_IDC_EXPLICIT_BIT_KHR = 128
M.VK_VIDEO_ENCODE_H264_STD_WEIGHTED_BIPRED_IDC_IMPLICIT_BIT_KHR = 256
M.VK_VIDEO_ENCODE_H264_STD_TRANSFORM_8X8_MODE_FLAG_SET_BIT_KHR = 512
M.VK_VIDEO_ENCODE_H264_STD_DIRECT_SPATIAL_MV_PRED_FLAG_UNSET_BIT_KHR = 1024
M.VK_VIDEO_ENCODE_H264_STD_ENTROPY_CODING_MODE_FLAG_UNSET_BIT_KHR = 2048
M.VK_VIDEO_ENCODE_H264_STD_ENTROPY_CODING_MODE_FLAG_SET_BIT_KHR = 4096
M.VK_VIDEO_ENCODE_H264_STD_DIRECT_8X8_INFERENCE_FLAG_UNSET_BIT_KHR = 8192
M.VK_VIDEO_ENCODE_H264_STD_CONSTRAINED_INTRA_PRED_FLAG_SET_BIT_KHR = 16384
M.VK_VIDEO_ENCODE_H264_STD_DEBLOCKING_FILTER_DISABLED_BIT_KHR = 32768
M.VK_VIDEO_ENCODE_H264_STD_DEBLOCKING_FILTER_ENABLED_BIT_KHR = 65536
M.VK_VIDEO_ENCODE_H264_STD_DEBLOCKING_FILTER_PARTIAL_BIT_KHR = 131072
M.VK_VIDEO_ENCODE_H264_STD_SLICE_QP_DELTA_BIT_KHR = 524288
M.VK_VIDEO_ENCODE_H264_STD_DIFFERENT_SLICE_QP_DELTA_BIT_KHR = 1048576
M.VK_VIDEO_ENCODE_H264_RATE_CONTROL_ATTEMPT_HRD_COMPLIANCE_BIT_KHR = 1
M.VK_VIDEO_ENCODE_H264_RATE_CONTROL_REGULAR_GOP_BIT_KHR = 2
M.VK_VIDEO_ENCODE_H264_RATE_CONTROL_REFERENCE_PATTERN_FLAT_BIT_KHR = 4
M.VK_VIDEO_ENCODE_H264_RATE_CONTROL_REFERENCE_PATTERN_DYADIC_BIT_KHR = 8
M.VK_VIDEO_ENCODE_H264_RATE_CONTROL_TEMPORAL_LAYER_PATTERN_DYADIC_BIT_KHR = 16
M.VK_HOST_IMAGE_COPY_MEMCPY_BIT = 1
M.VK_PARTITIONED_ACCELERATION_STRUCTURE_OP_TYPE_WRITE_INSTANCE_NV = 0
M.VK_PARTITIONED_ACCELERATION_STRUCTURE_OP_TYPE_UPDATE_INSTANCE_NV = 1
M.VK_PARTITIONED_ACCELERATION_STRUCTURE_OP_TYPE_WRITE_PARTITION_TRANSLATION_NV = 2
M.VK_PARTITIONED_ACCELERATION_STRUCTURE_INSTANCE_FLAG_TRIANGLE_FACING_CULL_DISABLE_BIT_NV = 1
M.VK_PARTITIONED_ACCELERATION_STRUCTURE_INSTANCE_FLAG_TRIANGLE_FLIP_FACING_BIT_NV = 2
M.VK_PARTITIONED_ACCELERATION_STRUCTURE_INSTANCE_FLAG_FORCE_OPAQUE_BIT_NV = 4
M.VK_PARTITIONED_ACCELERATION_STRUCTURE_INSTANCE_FLAG_FORCE_NO_OPAQUE_BIT_NV = 8
M.VK_PARTITIONED_ACCELERATION_STRUCTURE_INSTANCE_FLAG_ENABLE_EXPLICIT_BOUNDING_BOX_NV = 16
M.VK_IMAGE_CONSTRAINTS_INFO_CPU_READ_RARELY_FUCHSIA = 1
M.VK_IMAGE_CONSTRAINTS_INFO_CPU_READ_OFTEN_FUCHSIA = 2
M.VK_IMAGE_CONSTRAINTS_INFO_CPU_WRITE_RARELY_FUCHSIA = 4
M.VK_IMAGE_CONSTRAINTS_INFO_CPU_WRITE_OFTEN_FUCHSIA = 8
M.VK_IMAGE_CONSTRAINTS_INFO_PROTECTED_OPTIONAL_FUCHSIA = 16
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_BIT = 1
M.VK_FORMAT_FEATURE_2_STORAGE_IMAGE_BIT = 2
M.VK_FORMAT_FEATURE_2_STORAGE_IMAGE_ATOMIC_BIT = 4
M.VK_FORMAT_FEATURE_2_UNIFORM_TEXEL_BUFFER_BIT = 8
M.VK_FORMAT_FEATURE_2_STORAGE_TEXEL_BUFFER_BIT = 16
M.VK_FORMAT_FEATURE_2_STORAGE_TEXEL_BUFFER_ATOMIC_BIT = 32
M.VK_FORMAT_FEATURE_2_VERTEX_BUFFER_BIT = 64
M.VK_FORMAT_FEATURE_2_COLOR_ATTACHMENT_BIT = 128
M.VK_FORMAT_FEATURE_2_COLOR_ATTACHMENT_BLEND_BIT = 256
M.VK_FORMAT_FEATURE_2_DEPTH_STENCIL_ATTACHMENT_BIT = 512
M.VK_FORMAT_FEATURE_2_BLIT_SRC_BIT = 1024
M.VK_FORMAT_FEATURE_2_BLIT_DST_BIT = 2048
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_FILTER_LINEAR_BIT = 4096
M.VK_FORMAT_FEATURE_2_TRANSFER_SRC_BIT = 16384
M.VK_FORMAT_FEATURE_2_TRANSFER_DST_BIT = 32768
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_FILTER_MINMAX_BIT = 65536
M.VK_FORMAT_FEATURE_2_MIDPOINT_CHROMA_SAMPLES_BIT = 131072
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT = 262144
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT = 524288
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_BIT = 1048576
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_BIT = 2097152
M.VK_FORMAT_FEATURE_2_DISJOINT_BIT = 4194304
M.VK_FORMAT_FEATURE_2_COSITED_CHROMA_SAMPLES_BIT = 8388608
M.VK_FORMAT_FEATURE_2_STORAGE_READ_WITHOUT_FORMAT_BIT = 2147483648
M.VK_FORMAT_FEATURE_2_STORAGE_WRITE_WITHOUT_FORMAT_BIT = 4294967296
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_DEPTH_COMPARISON_BIT = 8589934592
M.VK_RENDERING_CONTENTS_SECONDARY_COMMAND_BUFFERS_BIT = 1
M.VK_RENDERING_SUSPENDING_BIT = 2
M.VK_RENDERING_RESUMING_BIT = 4
M.VK_VIDEO_ENCODE_H265_CAPABILITY_HRD_COMPLIANCE_BIT_KHR = 1
M.VK_VIDEO_ENCODE_H265_CAPABILITY_PREDICTION_WEIGHT_TABLE_GENERATED_BIT_KHR = 2
M.VK_VIDEO_ENCODE_H265_CAPABILITY_ROW_UNALIGNED_SLICE_SEGMENT_BIT_KHR = 4
M.VK_VIDEO_ENCODE_H265_CAPABILITY_DIFFERENT_SLICE_SEGMENT_TYPE_BIT_KHR = 8
M.VK_VIDEO_ENCODE_H265_CAPABILITY_B_FRAME_IN_L0_LIST_BIT_KHR = 16
M.VK_VIDEO_ENCODE_H265_CAPABILITY_B_FRAME_IN_L1_LIST_BIT_KHR = 32
M.VK_VIDEO_ENCODE_H265_CAPABILITY_PER_PICTURE_TYPE_MIN_MAX_QP_BIT_KHR = 64
M.VK_VIDEO_ENCODE_H265_CAPABILITY_PER_SLICE_SEGMENT_CONSTANT_QP_BIT_KHR = 128
M.VK_VIDEO_ENCODE_H265_CAPABILITY_MULTIPLE_TILES_PER_SLICE_SEGMENT_BIT_KHR = 256
M.VK_VIDEO_ENCODE_H265_CAPABILITY_MULTIPLE_SLICE_SEGMENTS_PER_TILE_BIT_KHR = 512
M.VK_VIDEO_ENCODE_H265_STD_SEPARATE_COLOR_PLANE_FLAG_SET_BIT_KHR = 1
M.VK_VIDEO_ENCODE_H265_STD_SAMPLE_ADAPTIVE_OFFSET_ENABLED_FLAG_SET_BIT_KHR = 2
M.VK_VIDEO_ENCODE_H265_STD_SCALING_LIST_DATA_PRESENT_FLAG_SET_BIT_KHR = 4
M.VK_VIDEO_ENCODE_H265_STD_PCM_ENABLED_FLAG_SET_BIT_KHR = 8
M.VK_VIDEO_ENCODE_H265_STD_SPS_TEMPORAL_MVP_ENABLED_FLAG_SET_BIT_KHR = 16
M.VK_VIDEO_ENCODE_H265_STD_INIT_QP_MINUS26_BIT_KHR = 32
M.VK_VIDEO_ENCODE_H265_STD_WEIGHTED_PRED_FLAG_SET_BIT_KHR = 64
M.VK_VIDEO_ENCODE_H265_STD_WEIGHTED_BIPRED_FLAG_SET_BIT_KHR = 128
M.VK_VIDEO_ENCODE_H265_STD_LOG2_PARALLEL_MERGE_LEVEL_MINUS2_BIT_KHR = 256
M.VK_VIDEO_ENCODE_H265_STD_SIGN_DATA_HIDING_ENABLED_FLAG_SET_BIT_KHR = 512
M.VK_VIDEO_ENCODE_H265_STD_TRANSFORM_SKIP_ENABLED_FLAG_SET_BIT_KHR = 1024
M.VK_VIDEO_ENCODE_H265_STD_TRANSFORM_SKIP_ENABLED_FLAG_UNSET_BIT_KHR = 2048
M.VK_VIDEO_ENCODE_H265_STD_PPS_SLICE_CHROMA_QP_OFFSETS_PRESENT_FLAG_SET_BIT_KHR = 4096
M.VK_VIDEO_ENCODE_H265_STD_TRANSQUANT_BYPASS_ENABLED_FLAG_SET_BIT_KHR = 8192
M.VK_VIDEO_ENCODE_H265_STD_CONSTRAINED_INTRA_PRED_FLAG_SET_BIT_KHR = 16384
M.VK_VIDEO_ENCODE_H265_STD_ENTROPY_CODING_SYNC_ENABLED_FLAG_SET_BIT_KHR = 32768
M.VK_VIDEO_ENCODE_H265_STD_DEBLOCKING_FILTER_OVERRIDE_ENABLED_FLAG_SET_BIT_KHR = 65536
M.VK_VIDEO_ENCODE_H265_STD_DEPENDENT_SLICE_SEGMENTS_ENABLED_FLAG_SET_BIT_KHR = 131072
M.VK_VIDEO_ENCODE_H265_STD_DEPENDENT_SLICE_SEGMENT_FLAG_SET_BIT_KHR = 262144
M.VK_VIDEO_ENCODE_H265_STD_SLICE_QP_DELTA_BIT_KHR = 524288
M.VK_VIDEO_ENCODE_H265_STD_DIFFERENT_SLICE_QP_DELTA_BIT_KHR = 1048576
M.VK_VIDEO_ENCODE_H265_RATE_CONTROL_ATTEMPT_HRD_COMPLIANCE_BIT_KHR = 1
M.VK_VIDEO_ENCODE_H265_RATE_CONTROL_REGULAR_GOP_BIT_KHR = 2
M.VK_VIDEO_ENCODE_H265_RATE_CONTROL_REFERENCE_PATTERN_FLAT_BIT_KHR = 4
M.VK_VIDEO_ENCODE_H265_RATE_CONTROL_REFERENCE_PATTERN_DYADIC_BIT_KHR = 8
M.VK_VIDEO_ENCODE_H265_RATE_CONTROL_TEMPORAL_SUB_LAYER_PATTERN_DYADIC_BIT_KHR = 16
M.VK_VIDEO_ENCODE_H265_CTB_SIZE_16_BIT_KHR = 1
M.VK_VIDEO_ENCODE_H265_CTB_SIZE_32_BIT_KHR = 2
M.VK_VIDEO_ENCODE_H265_CTB_SIZE_64_BIT_KHR = 4
M.VK_VIDEO_ENCODE_H265_TRANSFORM_BLOCK_SIZE_4_BIT_KHR = 1
M.VK_VIDEO_ENCODE_H265_TRANSFORM_BLOCK_SIZE_8_BIT_KHR = 2
M.VK_VIDEO_ENCODE_H265_TRANSFORM_BLOCK_SIZE_16_BIT_KHR = 4
M.VK_VIDEO_ENCODE_H265_TRANSFORM_BLOCK_SIZE_32_BIT_KHR = 8
M.VK_VIDEO_ENCODE_AV1_CAPABILITY_PER_RATE_CONTROL_GROUP_MIN_MAX_Q_INDEX_BIT_KHR = 1
M.VK_VIDEO_ENCODE_AV1_CAPABILITY_GENERATE_OBU_EXTENSION_HEADER_BIT_KHR = 2
M.VK_VIDEO_ENCODE_AV1_CAPABILITY_PRIMARY_REFERENCE_CDF_ONLY_BIT_KHR = 4
M.VK_VIDEO_ENCODE_AV1_CAPABILITY_FRAME_SIZE_OVERRIDE_BIT_KHR = 8
M.VK_VIDEO_ENCODE_AV1_CAPABILITY_MOTION_VECTOR_SCALING_BIT_KHR = 16
M.VK_VIDEO_ENCODE_AV1_STD_UNIFORM_TILE_SPACING_FLAG_SET_BIT_KHR = 1
M.VK_VIDEO_ENCODE_AV1_STD_SKIP_MODE_PRESENT_UNSET_BIT_KHR = 2
M.VK_VIDEO_ENCODE_AV1_STD_PRIMARY_REF_FRAME_BIT_KHR = 4
M.VK_VIDEO_ENCODE_AV1_STD_DELTA_Q_BIT_KHR = 8
M.VK_VIDEO_ENCODE_AV1_RATE_CONTROL_REGULAR_GOP_BIT_KHR = 1
M.VK_VIDEO_ENCODE_AV1_RATE_CONTROL_TEMPORAL_LAYER_PATTERN_DYADIC_BIT_KHR = 2
M.VK_VIDEO_ENCODE_AV1_RATE_CONTROL_REFERENCE_PATTERN_FLAT_BIT_KHR = 4
M.VK_VIDEO_ENCODE_AV1_RATE_CONTROL_REFERENCE_PATTERN_DYADIC_BIT_KHR = 8
M.VK_VIDEO_ENCODE_AV1_SUPERBLOCK_SIZE_64_BIT_KHR = 1
M.VK_VIDEO_ENCODE_AV1_SUPERBLOCK_SIZE_128_BIT_KHR = 2
M.VK_VIDEO_ENCODE_AV1_PREDICTION_MODE_INTRA_ONLY_KHR = 0
M.VK_VIDEO_ENCODE_AV1_PREDICTION_MODE_SINGLE_REFERENCE_KHR = 1
M.VK_VIDEO_ENCODE_AV1_PREDICTION_MODE_UNIDIRECTIONAL_COMPOUND_KHR = 2
M.VK_VIDEO_ENCODE_AV1_PREDICTION_MODE_BIDIRECTIONAL_COMPOUND_KHR = 3
M.VK_VIDEO_ENCODE_AV1_RATE_CONTROL_GROUP_INTRA_KHR = 0
M.VK_VIDEO_ENCODE_AV1_RATE_CONTROL_GROUP_PREDICTIVE_KHR = 1
M.VK_VIDEO_ENCODE_AV1_RATE_CONTROL_GROUP_BIPREDICTIVE_KHR = 2
M.VK_EXPORT_METAL_OBJECT_TYPE_METAL_DEVICE_BIT_EXT = 1
M.VK_EXPORT_METAL_OBJECT_TYPE_METAL_COMMAND_QUEUE_BIT_EXT = 2
M.VK_EXPORT_METAL_OBJECT_TYPE_METAL_BUFFER_BIT_EXT = 4
M.VK_EXPORT_METAL_OBJECT_TYPE_METAL_TEXTURE_BIT_EXT = 8
M.VK_EXPORT_METAL_OBJECT_TYPE_METAL_IOSURFACE_BIT_EXT = 16
M.VK_EXPORT_METAL_OBJECT_TYPE_METAL_SHARED_EVENT_BIT_EXT = 32
M.VK_IMAGE_COMPRESSION_DEFAULT_EXT = 0
M.VK_IMAGE_COMPRESSION_FIXED_RATE_DEFAULT_EXT = 1
M.VK_IMAGE_COMPRESSION_FIXED_RATE_EXPLICIT_EXT = 2
M.VK_IMAGE_COMPRESSION_DISABLED_EXT = 4
M.VK_IMAGE_COMPRESSION_FIXED_RATE_NONE_EXT = 0
M.VK_IMAGE_COMPRESSION_FIXED_RATE_1BPC_BIT_EXT = 1
M.VK_IMAGE_COMPRESSION_FIXED_RATE_2BPC_BIT_EXT = 2
M.VK_IMAGE_COMPRESSION_FIXED_RATE_3BPC_BIT_EXT = 4
M.VK_IMAGE_COMPRESSION_FIXED_RATE_4BPC_BIT_EXT = 8
M.VK_IMAGE_COMPRESSION_FIXED_RATE_5BPC_BIT_EXT = 16
M.VK_IMAGE_COMPRESSION_FIXED_RATE_6BPC_BIT_EXT = 32
M.VK_IMAGE_COMPRESSION_FIXED_RATE_7BPC_BIT_EXT = 64
M.VK_IMAGE_COMPRESSION_FIXED_RATE_8BPC_BIT_EXT = 128
M.VK_IMAGE_COMPRESSION_FIXED_RATE_9BPC_BIT_EXT = 256
M.VK_IMAGE_COMPRESSION_FIXED_RATE_10BPC_BIT_EXT = 512
M.VK_IMAGE_COMPRESSION_FIXED_RATE_11BPC_BIT_EXT = 1024
M.VK_IMAGE_COMPRESSION_FIXED_RATE_12BPC_BIT_EXT = 2048
M.VK_IMAGE_COMPRESSION_FIXED_RATE_13BPC_BIT_EXT = 4096
M.VK_IMAGE_COMPRESSION_FIXED_RATE_14BPC_BIT_EXT = 8192
M.VK_IMAGE_COMPRESSION_FIXED_RATE_15BPC_BIT_EXT = 16384
M.VK_IMAGE_COMPRESSION_FIXED_RATE_16BPC_BIT_EXT = 32768
M.VK_IMAGE_COMPRESSION_FIXED_RATE_17BPC_BIT_EXT = 65536
M.VK_IMAGE_COMPRESSION_FIXED_RATE_18BPC_BIT_EXT = 131072
M.VK_IMAGE_COMPRESSION_FIXED_RATE_19BPC_BIT_EXT = 262144
M.VK_IMAGE_COMPRESSION_FIXED_RATE_20BPC_BIT_EXT = 524288
M.VK_IMAGE_COMPRESSION_FIXED_RATE_21BPC_BIT_EXT = 1048576
M.VK_IMAGE_COMPRESSION_FIXED_RATE_22BPC_BIT_EXT = 2097152
M.VK_IMAGE_COMPRESSION_FIXED_RATE_23BPC_BIT_EXT = 4194304
M.VK_IMAGE_COMPRESSION_FIXED_RATE_24BPC_BIT_EXT = 8388608
M.VK_PIPELINE_ROBUSTNESS_BUFFER_BEHAVIOR_DEVICE_DEFAULT = 0
M.VK_PIPELINE_ROBUSTNESS_BUFFER_BEHAVIOR_DISABLED = 1
M.VK_PIPELINE_ROBUSTNESS_BUFFER_BEHAVIOR_ROBUST_BUFFER_ACCESS = 2
M.VK_PIPELINE_ROBUSTNESS_BUFFER_BEHAVIOR_ROBUST_BUFFER_ACCESS_2 = 3
M.VK_PIPELINE_ROBUSTNESS_IMAGE_BEHAVIOR_DEVICE_DEFAULT = 0
M.VK_PIPELINE_ROBUSTNESS_IMAGE_BEHAVIOR_DISABLED = 1
M.VK_PIPELINE_ROBUSTNESS_IMAGE_BEHAVIOR_ROBUST_IMAGE_ACCESS = 2
M.VK_PIPELINE_ROBUSTNESS_IMAGE_BEHAVIOR_ROBUST_IMAGE_ACCESS_2 = 3
M.VK_OPTICAL_FLOW_GRID_SIZE_UNKNOWN_NV = 0
M.VK_OPTICAL_FLOW_GRID_SIZE_1X1_BIT_NV = 1
M.VK_OPTICAL_FLOW_GRID_SIZE_2X2_BIT_NV = 2
M.VK_OPTICAL_FLOW_GRID_SIZE_4X4_BIT_NV = 4
M.VK_OPTICAL_FLOW_GRID_SIZE_8X8_BIT_NV = 8
M.VK_OPTICAL_FLOW_USAGE_UNKNOWN_NV = 0
M.VK_OPTICAL_FLOW_USAGE_INPUT_BIT_NV = 1
M.VK_OPTICAL_FLOW_USAGE_OUTPUT_BIT_NV = 2
M.VK_OPTICAL_FLOW_USAGE_HINT_BIT_NV = 4
M.VK_OPTICAL_FLOW_USAGE_COST_BIT_NV = 8
M.VK_OPTICAL_FLOW_USAGE_GLOBAL_FLOW_BIT_NV = 16
M.VK_OPTICAL_FLOW_PERFORMANCE_LEVEL_UNKNOWN_NV = 0
M.VK_OPTICAL_FLOW_PERFORMANCE_LEVEL_SLOW_NV = 1
M.VK_OPTICAL_FLOW_PERFORMANCE_LEVEL_MEDIUM_NV = 2
M.VK_OPTICAL_FLOW_PERFORMANCE_LEVEL_FAST_NV = 3
M.VK_OPTICAL_FLOW_SESSION_BINDING_POINT_UNKNOWN_NV = 0
M.VK_OPTICAL_FLOW_SESSION_BINDING_POINT_INPUT_NV = 1
M.VK_OPTICAL_FLOW_SESSION_BINDING_POINT_REFERENCE_NV = 2
M.VK_OPTICAL_FLOW_SESSION_BINDING_POINT_HINT_NV = 3
M.VK_OPTICAL_FLOW_SESSION_BINDING_POINT_FLOW_VECTOR_NV = 4
M.VK_OPTICAL_FLOW_SESSION_BINDING_POINT_BACKWARD_FLOW_VECTOR_NV = 5
M.VK_OPTICAL_FLOW_SESSION_BINDING_POINT_COST_NV = 6
M.VK_OPTICAL_FLOW_SESSION_BINDING_POINT_BACKWARD_COST_NV = 7
M.VK_OPTICAL_FLOW_SESSION_BINDING_POINT_GLOBAL_FLOW_NV = 8
M.VK_OPTICAL_FLOW_SESSION_CREATE_ENABLE_HINT_BIT_NV = 1
M.VK_OPTICAL_FLOW_SESSION_CREATE_ENABLE_COST_BIT_NV = 2
M.VK_OPTICAL_FLOW_SESSION_CREATE_ENABLE_GLOBAL_FLOW_BIT_NV = 4
M.VK_OPTICAL_FLOW_SESSION_CREATE_ALLOW_REGIONS_BIT_NV = 8
M.VK_OPTICAL_FLOW_SESSION_CREATE_BOTH_DIRECTIONS_BIT_NV = 16
M.VK_OPTICAL_FLOW_EXECUTE_DISABLE_TEMPORAL_HINTS_BIT_NV = 1
M.VK_MICROMAP_TYPE_OPACITY_MICROMAP_EXT = 0
M.VK_BUILD_MICROMAP_PREFER_FAST_TRACE_BIT_EXT = 1
M.VK_BUILD_MICROMAP_PREFER_FAST_BUILD_BIT_EXT = 2
M.VK_BUILD_MICROMAP_ALLOW_COMPACTION_BIT_EXT = 4
M.VK_MICROMAP_CREATE_DEVICE_ADDRESS_CAPTURE_REPLAY_BIT_EXT = 1
M.VK_COPY_MICROMAP_MODE_CLONE_EXT = 0
M.VK_COPY_MICROMAP_MODE_SERIALIZE_EXT = 1
M.VK_COPY_MICROMAP_MODE_DESERIALIZE_EXT = 2
M.VK_COPY_MICROMAP_MODE_COMPACT_EXT = 3
M.VK_BUILD_MICROMAP_MODE_BUILD_EXT = 0
M.VK_OPACITY_MICROMAP_FORMAT_2_STATE_EXT = 1
M.VK_OPACITY_MICROMAP_FORMAT_4_STATE_EXT = 2
M.VK_OPACITY_MICROMAP_SPECIAL_INDEX_FULLY_TRANSPARENT_EXT = -1
M.VK_OPACITY_MICROMAP_SPECIAL_INDEX_FULLY_OPAQUE_EXT = -2
M.VK_OPACITY_MICROMAP_SPECIAL_INDEX_FULLY_UNKNOWN_TRANSPARENT_EXT = -3
M.VK_OPACITY_MICROMAP_SPECIAL_INDEX_FULLY_UNKNOWN_OPAQUE_EXT = -4
M.VK_DEPTH_BIAS_REPRESENTATION_LEAST_REPRESENTABLE_VALUE_FORMAT_EXT = 0
M.VK_DEPTH_BIAS_REPRESENTATION_LEAST_REPRESENTABLE_VALUE_FORCE_UNORM_EXT = 1
M.VK_DEPTH_BIAS_REPRESENTATION_FLOAT_EXT = 2
M.VK_DEVICE_FAULT_ADDRESS_TYPE_NONE_EXT = 0
M.VK_DEVICE_FAULT_ADDRESS_TYPE_READ_INVALID_EXT = 1
M.VK_DEVICE_FAULT_ADDRESS_TYPE_WRITE_INVALID_EXT = 2
M.VK_DEVICE_FAULT_ADDRESS_TYPE_EXECUTE_INVALID_EXT = 3
M.VK_DEVICE_FAULT_ADDRESS_TYPE_INSTRUCTION_POINTER_UNKNOWN_EXT = 4
M.VK_DEVICE_FAULT_ADDRESS_TYPE_INSTRUCTION_POINTER_INVALID_EXT = 5
M.VK_DEVICE_FAULT_ADDRESS_TYPE_INSTRUCTION_POINTER_FAULT_EXT = 6
M.VK_DEVICE_FAULT_VENDOR_BINARY_HEADER_VERSION_ONE_EXT = 1
M.VK_INDIRECT_COMMANDS_LAYOUT_USAGE_EXPLICIT_PREPROCESS_BIT_EXT = 1
M.VK_INDIRECT_COMMANDS_LAYOUT_USAGE_UNORDERED_SEQUENCES_BIT_EXT = 2
M.VK_INDIRECT_EXECUTION_SET_INFO_TYPE_PIPELINES_EXT = 0
M.VK_INDIRECT_EXECUTION_SET_INFO_TYPE_SHADER_OBJECTS_EXT = 1
M.VK_INDIRECT_COMMANDS_INPUT_MODE_VULKAN_INDEX_BUFFER_EXT = 1
M.VK_INDIRECT_COMMANDS_INPUT_MODE_DXGI_INDEX_BUFFER_EXT = 2
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_EXECUTION_SET_EXT = 0
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_PUSH_CONSTANT_EXT = 1
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_SEQUENCE_INDEX_EXT = 2
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_INDEX_BUFFER_EXT = 3
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_VERTEX_BUFFER_EXT = 4
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_INDEXED_EXT = 5
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_EXT = 6
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_INDEXED_COUNT_EXT = 7
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_COUNT_EXT = 8
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DISPATCH_EXT = 9
M.VK_DISPLACEMENT_MICROMAP_FORMAT_64_TRIANGLES_64_BYTES_NV = 1
M.VK_DISPLACEMENT_MICROMAP_FORMAT_256_TRIANGLES_128_BYTES_NV = 2
M.VK_DISPLACEMENT_MICROMAP_FORMAT_1024_TRIANGLES_128_BYTES_NV = 3
M.VK_SHADER_CREATE_LINK_STAGE_BIT_EXT = 1
M.VK_SHADER_CODE_TYPE_BINARY_EXT = 0
M.VK_SHADER_CODE_TYPE_SPIRV_EXT = 1
M.VK_SCOPE_DEVICE_KHR = 1
M.VK_SCOPE_WORKGROUP_KHR = 2
M.VK_SCOPE_SUBGROUP_KHR = 3
M.VK_SCOPE_QUEUE_FAMILY_KHR = 5
M.VK_COMPONENT_TYPE_FLOAT16_KHR = 0
M.VK_COMPONENT_TYPE_FLOAT32_KHR = 1
M.VK_COMPONENT_TYPE_FLOAT64_KHR = 2
M.VK_COMPONENT_TYPE_SINT8_KHR = 3
M.VK_COMPONENT_TYPE_SINT16_KHR = 4
M.VK_COMPONENT_TYPE_SINT32_KHR = 5
M.VK_COMPONENT_TYPE_SINT64_KHR = 6
M.VK_COMPONENT_TYPE_UINT8_KHR = 7
M.VK_COMPONENT_TYPE_UINT16_KHR = 8
M.VK_COMPONENT_TYPE_UINT32_KHR = 9
M.VK_COMPONENT_TYPE_UINT64_KHR = 10
M.VK_CUBIC_FILTER_WEIGHTS_CATMULL_ROM_QCOM = 0
M.VK_CUBIC_FILTER_WEIGHTS_ZERO_TANGENT_CARDINAL_QCOM = 1
M.VK_CUBIC_FILTER_WEIGHTS_B_SPLINE_QCOM = 2
M.VK_CUBIC_FILTER_WEIGHTS_MITCHELL_NETRAVALI_QCOM = 3
M.VK_BLOCK_MATCH_WINDOW_COMPARE_MODE_MIN_QCOM = 0
M.VK_BLOCK_MATCH_WINDOW_COMPARE_MODE_MAX_QCOM = 1
M.VK_PHYSICAL_DEVICE_LAYERED_API_VULKAN_KHR = 0
M.VK_PHYSICAL_DEVICE_LAYERED_API_D3D12_KHR = 1
M.VK_PHYSICAL_DEVICE_LAYERED_API_METAL_KHR = 2
M.VK_PHYSICAL_DEVICE_LAYERED_API_OPENGL_KHR = 3
M.VK_PHYSICAL_DEVICE_LAYERED_API_OPENGLES_KHR = 4
M.VK_LAYERED_DRIVER_UNDERLYING_API_NONE_MSFT = 0
M.VK_LAYERED_DRIVER_UNDERLYING_API_D3D12_MSFT = 1
M.VK_LATENCY_MARKER_SIMULATION_START_NV = 0
M.VK_LATENCY_MARKER_SIMULATION_END_NV = 1
M.VK_LATENCY_MARKER_RENDERSUBMIT_START_NV = 2
M.VK_LATENCY_MARKER_RENDERSUBMIT_END_NV = 3
M.VK_LATENCY_MARKER_PRESENT_START_NV = 4
M.VK_LATENCY_MARKER_PRESENT_END_NV = 5
M.VK_LATENCY_MARKER_INPUT_SAMPLE_NV = 6
M.VK_LATENCY_MARKER_TRIGGER_FLASH_NV = 7
M.VK_LATENCY_MARKER_OUT_OF_BAND_RENDERSUBMIT_START_NV = 8
M.VK_LATENCY_MARKER_OUT_OF_BAND_RENDERSUBMIT_END_NV = 9
M.VK_LATENCY_MARKER_OUT_OF_BAND_PRESENT_START_NV = 10
M.VK_LATENCY_MARKER_OUT_OF_BAND_PRESENT_END_NV = 11
M.VK_OUT_OF_BAND_QUEUE_TYPE_RENDER_NV = 0
M.VK_OUT_OF_BAND_QUEUE_TYPE_PRESENT_NV = 1
M.VK_COMPRESSED_TRIANGLE_FORMAT_DGF1_AMDX = 0
M.VK_DEPTH_CLAMP_MODE_VIEWPORT_RANGE_EXT = 0
M.VK_DEPTH_CLAMP_MODE_USER_DEFINED_RANGE_EXT = 1
M.VK_ACCESS_3_NONE_KHR = 0
M.VK_TILE_SHADING_RENDER_PASS_ENABLE_BIT_QCOM = 1
M.VK_TILE_SHADING_RENDER_PASS_PER_TILE_EXECUTION_BIT_QCOM = 2
M.VK_COOPERATIVE_VECTOR_MATRIX_LAYOUT_ROW_MAJOR_NV = 0
M.VK_COOPERATIVE_VECTOR_MATRIX_LAYOUT_COLUMN_MAJOR_NV = 1
M.VK_COOPERATIVE_VECTOR_MATRIX_LAYOUT_INFERENCING_OPTIMAL_NV = 2
M.VK_COOPERATIVE_VECTOR_MATRIX_LAYOUT_TRAINING_OPTIMAL_NV = 3
M.VK_ADDRESS_COPY_DEVICE_LOCAL_BIT_KHR = 1
M.VK_ADDRESS_COPY_SPARSE_BIT_KHR = 2
M.VK_ADDRESS_COPY_PROTECTED_BIT_KHR = 4
M.VK_TENSOR_CREATE_MUTABLE_FORMAT_BIT_ARM = 1
M.VK_TENSOR_CREATE_PROTECTED_BIT_ARM = 2
M.VK_TENSOR_USAGE_SHADER_BIT_ARM = 2
M.VK_TENSOR_USAGE_TRANSFER_SRC_BIT_ARM = 4
M.VK_TENSOR_USAGE_TRANSFER_DST_BIT_ARM = 8
M.VK_TENSOR_USAGE_IMAGE_ALIASING_BIT_ARM = 16
M.VK_TENSOR_TILING_OPTIMAL_ARM = 0
M.VK_TENSOR_TILING_LINEAR_ARM = 1
M.VK_DEFAULT_VERTEX_ATTRIBUTE_VALUE_ZERO_ZERO_ZERO_ZERO_KHR = 0
M.VK_DEFAULT_VERTEX_ATTRIBUTE_VALUE_ZERO_ZERO_ZERO_ONE_KHR = 1
M.VK_DATA_GRAPH_PIPELINE_SESSION_CREATE_PROTECTED_BIT_ARM = 1
M.VK_DATA_GRAPH_PIPELINE_SESSION_BIND_POINT_TRANSIENT_ARM = 0
M.VK_DATA_GRAPH_PIPELINE_SESSION_BIND_POINT_TYPE_MEMORY_ARM = 0
M.VK_DATA_GRAPH_PIPELINE_PROPERTY_CREATION_LOG_ARM = 0
M.VK_DATA_GRAPH_PIPELINE_PROPERTY_IDENTIFIER_ARM = 1
M.VK_PHYSICAL_DEVICE_DATA_GRAPH_PROCESSING_ENGINE_TYPE_DEFAULT_ARM = 0
M.VK_PHYSICAL_DEVICE_DATA_GRAPH_OPERATION_TYPE_SPIRV_EXTENDED_INSTRUCTION_SET_ARM = 0
M.VK_DATA_GRAPH_MODEL_CACHE_TYPE_GENERIC_BINARY_QCOM = 0
M.VK_VIDEO_ENCODE_RGB_MODEL_CONVERSION_RGB_IDENTITY_BIT_VALVE = 1
M.VK_VIDEO_ENCODE_RGB_MODEL_CONVERSION_YCBCR_IDENTITY_BIT_VALVE = 2
M.VK_VIDEO_ENCODE_RGB_MODEL_CONVERSION_YCBCR_709_BIT_VALVE = 4
M.VK_VIDEO_ENCODE_RGB_MODEL_CONVERSION_YCBCR_601_BIT_VALVE = 8
M.VK_VIDEO_ENCODE_RGB_MODEL_CONVERSION_YCBCR_2020_BIT_VALVE = 16
M.VK_VIDEO_ENCODE_RGB_RANGE_COMPRESSION_FULL_RANGE_BIT_VALVE = 1
M.VK_VIDEO_ENCODE_RGB_RANGE_COMPRESSION_NARROW_RANGE_BIT_VALVE = 2
M.VK_VIDEO_ENCODE_RGB_CHROMA_OFFSET_COSITED_EVEN_BIT_VALVE = 1
M.VK_VIDEO_ENCODE_RGB_CHROMA_OFFSET_MIDPOINT_BIT_VALVE = 2
M.VK_SWAPCHAIN_IMAGE_USAGE_SHARED_BIT_OHOS = 1
M.VK_DESCRIPTOR_MAPPING_SOURCE_HEAP_WITH_CONSTANT_OFFSET_EXT = 0
M.VK_DESCRIPTOR_MAPPING_SOURCE_HEAP_WITH_PUSH_INDEX_EXT = 1
M.VK_DESCRIPTOR_MAPPING_SOURCE_HEAP_WITH_INDIRECT_INDEX_EXT = 2
M.VK_DESCRIPTOR_MAPPING_SOURCE_HEAP_WITH_INDIRECT_INDEX_ARRAY_EXT = 3
M.VK_DESCRIPTOR_MAPPING_SOURCE_RESOURCE_HEAP_DATA_EXT = 4
M.VK_DESCRIPTOR_MAPPING_SOURCE_PUSH_DATA_EXT = 5
M.VK_DESCRIPTOR_MAPPING_SOURCE_PUSH_ADDRESS_EXT = 6
M.VK_DESCRIPTOR_MAPPING_SOURCE_INDIRECT_ADDRESS_EXT = 7
M.VK_SPIRV_RESOURCE_TYPE_ALL_EXT = 0x7
M.VK_SPIRV_RESOURCE_TYPE_SAMPLER_BIT_EXT = 1
M.VK_SPIRV_RESOURCE_TYPE_SAMPLED_IMAGE_BIT_EXT = 2
M.VK_SPIRV_RESOURCE_TYPE_READ_ONLY_IMAGE_BIT_EXT = 4
M.VK_SPIRV_RESOURCE_TYPE_READ_WRITE_IMAGE_BIT_EXT = 8
M.VK_SPIRV_RESOURCE_TYPE_COMBINED_SAMPLED_IMAGE_BIT_EXT = 16
M.VK_SPIRV_RESOURCE_TYPE_UNIFORM_BUFFER_BIT_EXT = 32
M.VK_SPIRV_RESOURCE_TYPE_READ_ONLY_STORAGE_BUFFER_BIT_EXT = 64
M.VK_SPIRV_RESOURCE_TYPE_READ_WRITE_STORAGE_BUFFER_BIT_EXT = 128
M.VK_STENCIL_FRONT_AND_BACK = 0x00000003
M.VK_COLORSPACE_SRGB_NONLINEAR_KHR = 0
M.VK_DEBUG_REPORT_OBJECT_TYPE_DEBUG_REPORT_EXT = 28
M.VK_DEBUG_REPORT_OBJECT_TYPE_VALIDATION_CACHE_EXT = 33
M.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D11_FENCE_BIT = 8
M.VK_SURFACE_COUNTER_VBLANK_EXT = 1
M.VK_GEOMETRY_INSTANCE_TRIANGLE_FRONT_COUNTERCLOCKWISE_BIT_KHR = 2
M.VK_QUERY_SCOPE_COMMAND_BUFFER_KHR = 0
M.VK_QUERY_SCOPE_RENDER_PASS_KHR = 1
M.VK_QUERY_SCOPE_COMMAND_KHR = 2
M.VK_MEMORY_DECOMPRESSION_METHOD_GDEFLATE_1_0_BIT_NV = 1
M.VK_PERFORMANCE_COUNTER_DESCRIPTION_PERFORMANCE_IMPACTING_KHR = 1
M.VK_PERFORMANCE_COUNTER_DESCRIPTION_CONCURRENTLY_IMPACTED_KHR = 2
M.VK_PIPELINE_STAGE_2_TRANSFER_BIT = 4096
M.VK_PRESENT_SCALING_ONE_TO_ONE_BIT_EXT = 1
M.VK_PRESENT_SCALING_ASPECT_RATIO_STRETCH_BIT_EXT = 2
M.VK_PRESENT_SCALING_STRETCH_BIT_EXT = 4
M.VK_PRESENT_GRAVITY_MIN_BIT_EXT = 1
M.VK_PRESENT_GRAVITY_MAX_BIT_EXT = 2
M.VK_PRESENT_GRAVITY_CENTERED_BIT_EXT = 4
M.VK_HOST_IMAGE_COPY_MEMCPY = 1
M.VK_ERROR_SURFACE_LOST_KHR = -1000000000
M.VK_ERROR_NATIVE_WINDOW_IN_USE_KHR = -1000000001
M.VK_OBJECT_TYPE_SURFACE_KHR = 1000000000
M.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR = 1000001000
M.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR = 1000001001
M.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR = 1000001002
M.VK_SUBOPTIMAL_KHR = 1000001003
M.VK_ERROR_OUT_OF_DATE_KHR = -1000001004
M.VK_OBJECT_TYPE_SWAPCHAIN_KHR = 1000001000
M.VK_STRUCTURE_TYPE_DEVICE_GROUP_PRESENT_CAPABILITIES_KHR = 1000060007
M.VK_STRUCTURE_TYPE_IMAGE_SWAPCHAIN_CREATE_INFO_KHR = 1000060008
M.VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_SWAPCHAIN_INFO_KHR = 1000060009
M.VK_STRUCTURE_TYPE_ACQUIRE_NEXT_IMAGE_INFO_KHR = 1000060010
M.VK_STRUCTURE_TYPE_DEVICE_GROUP_PRESENT_INFO_KHR = 1000060011
M.VK_STRUCTURE_TYPE_DEVICE_GROUP_SWAPCHAIN_CREATE_INFO_KHR = 1000060012
M.VK_STRUCTURE_TYPE_DISPLAY_MODE_CREATE_INFO_KHR = 1000002000
M.VK_STRUCTURE_TYPE_DISPLAY_SURFACE_CREATE_INFO_KHR = 1000002001
M.VK_OBJECT_TYPE_DISPLAY_KHR = 1000002000
M.VK_OBJECT_TYPE_DISPLAY_MODE_KHR = 1000002001
M.VK_STRUCTURE_TYPE_DISPLAY_PRESENT_INFO_KHR = 1000003000
M.VK_ERROR_INCOMPATIBLE_DISPLAY_KHR = -1000003001
M.VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR = 1000004000
M.VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR = 1000005000
M.VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR = 1000006000
M.VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR = 1000008000
M.VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR = 1000009000
M.VK_STRUCTURE_TYPE_NATIVE_BUFFER_ANDROID = 1000010000
M.VK_STRUCTURE_TYPE_SWAPCHAIN_IMAGE_CREATE_INFO_ANDROID = 1000010001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENTATION_PROPERTIES_ANDROID = 1000010002
M.VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT = 1000011000
M.VK_STRUCTURE_TYPE_DEBUG_REPORT_CREATE_INFO_EXT = 1000011000
M.VK_OBJECT_TYPE_DEBUG_REPORT_CALLBACK_EXT = 1000011000
M.VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_EXT = 1000156000
M.VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_EXT = 1000085000
M.VK_ERROR_INVALID_SHADER_NV = -1000012000
M.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_RASTERIZATION_ORDER_AMD = 1000018000
M.VK_STRUCTURE_TYPE_DEBUG_MARKER_OBJECT_NAME_INFO_EXT = 1000022000
M.VK_STRUCTURE_TYPE_DEBUG_MARKER_OBJECT_TAG_INFO_EXT = 1000022001
M.VK_STRUCTURE_TYPE_DEBUG_MARKER_MARKER_INFO_EXT = 1000022002
M.VK_STRUCTURE_TYPE_VIDEO_PROFILE_INFO_KHR = 1000023000
M.VK_STRUCTURE_TYPE_VIDEO_CAPABILITIES_KHR = 1000023001
M.VK_STRUCTURE_TYPE_VIDEO_PICTURE_RESOURCE_INFO_KHR = 1000023002
M.VK_STRUCTURE_TYPE_VIDEO_SESSION_MEMORY_REQUIREMENTS_KHR = 1000023003
M.VK_STRUCTURE_TYPE_BIND_VIDEO_SESSION_MEMORY_INFO_KHR = 1000023004
M.VK_STRUCTURE_TYPE_VIDEO_SESSION_CREATE_INFO_KHR = 1000023005
M.VK_STRUCTURE_TYPE_VIDEO_SESSION_PARAMETERS_CREATE_INFO_KHR = 1000023006
M.VK_STRUCTURE_TYPE_VIDEO_SESSION_PARAMETERS_UPDATE_INFO_KHR = 1000023007
M.VK_STRUCTURE_TYPE_VIDEO_BEGIN_CODING_INFO_KHR = 1000023008
M.VK_STRUCTURE_TYPE_VIDEO_END_CODING_INFO_KHR = 1000023009
M.VK_STRUCTURE_TYPE_VIDEO_CODING_CONTROL_INFO_KHR = 1000023010
M.VK_STRUCTURE_TYPE_VIDEO_REFERENCE_SLOT_INFO_KHR = 1000023011
M.VK_STRUCTURE_TYPE_QUEUE_FAMILY_VIDEO_PROPERTIES_KHR = 1000023012
M.VK_STRUCTURE_TYPE_VIDEO_PROFILE_LIST_INFO_KHR = 1000023013
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VIDEO_FORMAT_INFO_KHR = 1000023014
M.VK_STRUCTURE_TYPE_VIDEO_FORMAT_PROPERTIES_KHR = 1000023015
M.VK_STRUCTURE_TYPE_QUEUE_FAMILY_QUERY_RESULT_STATUS_PROPERTIES_KHR = 1000023016
M.VK_OBJECT_TYPE_VIDEO_SESSION_KHR = 1000023000
M.VK_OBJECT_TYPE_VIDEO_SESSION_PARAMETERS_KHR = 1000023001
M.VK_QUERY_TYPE_RESULT_STATUS_ONLY_KHR = 1000023000
M.VK_ERROR_IMAGE_USAGE_NOT_SUPPORTED_KHR = -1000023000
M.VK_ERROR_VIDEO_PICTURE_LAYOUT_NOT_SUPPORTED_KHR = -1000023001
M.VK_ERROR_VIDEO_PROFILE_OPERATION_NOT_SUPPORTED_KHR = -1000023002
M.VK_ERROR_VIDEO_PROFILE_FORMAT_NOT_SUPPORTED_KHR = -1000023003
M.VK_ERROR_VIDEO_PROFILE_CODEC_NOT_SUPPORTED_KHR = -1000023004
M.VK_ERROR_VIDEO_STD_VERSION_NOT_SUPPORTED_KHR = -1000023005
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_INFO_KHR = 1000024000
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_CAPABILITIES_KHR = 1000024001
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_USAGE_INFO_KHR = 1000024002
M.VK_IMAGE_LAYOUT_VIDEO_DECODE_DST_KHR = 1000024000
M.VK_IMAGE_LAYOUT_VIDEO_DECODE_SRC_KHR = 1000024001
M.VK_IMAGE_LAYOUT_VIDEO_DECODE_DPB_KHR = 1000024002
M.VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_IMAGE_CREATE_INFO_NV = 1000026000
M.VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_BUFFER_CREATE_INFO_NV = 1000026001
M.VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_MEMORY_ALLOCATE_INFO_NV = 1000026002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_FEATURES_EXT = 1000028000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_PROPERTIES_EXT = 1000028001
M.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_STREAM_CREATE_INFO_EXT = 1000028002
M.VK_QUERY_TYPE_TRANSFORM_FEEDBACK_STREAM_EXT = 1000028004
M.VK_STRUCTURE_TYPE_CU_MODULE_CREATE_INFO_NVX = 1000029000
M.VK_STRUCTURE_TYPE_CU_FUNCTION_CREATE_INFO_NVX = 1000029001
M.VK_STRUCTURE_TYPE_CU_LAUNCH_INFO_NVX = 1000029002
M.VK_STRUCTURE_TYPE_CU_MODULE_TEXTURING_MODE_CREATE_INFO_NVX = 1000029004
M.VK_OBJECT_TYPE_CU_MODULE_NVX = 1000029000
M.VK_OBJECT_TYPE_CU_FUNCTION_NVX = 1000029001
M.VK_DEBUG_REPORT_OBJECT_TYPE_CU_MODULE_NVX_EXT = 1000029000
M.VK_DEBUG_REPORT_OBJECT_TYPE_CU_FUNCTION_NVX_EXT = 1000029001
M.VK_STRUCTURE_TYPE_IMAGE_VIEW_HANDLE_INFO_NVX = 1000030000
M.VK_STRUCTURE_TYPE_IMAGE_VIEW_ADDRESS_PROPERTIES_NVX = 1000030001
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_CAPABILITIES_KHR = 1000038000
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_SESSION_PARAMETERS_CREATE_INFO_KHR = 1000038001
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_SESSION_PARAMETERS_ADD_INFO_KHR = 1000038002
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_PICTURE_INFO_KHR = 1000038003
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_DPB_SLOT_INFO_KHR = 1000038004
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_NALU_SLICE_INFO_KHR = 1000038005
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_GOP_REMAINING_FRAME_INFO_KHR = 1000038006
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_PROFILE_INFO_KHR = 1000038007
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_RATE_CONTROL_INFO_KHR = 1000038008
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_RATE_CONTROL_LAYER_INFO_KHR = 1000038009
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_SESSION_CREATE_INFO_KHR = 1000038010
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_QUALITY_LEVEL_PROPERTIES_KHR = 1000038011
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_SESSION_PARAMETERS_GET_INFO_KHR = 1000038012
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_SESSION_PARAMETERS_FEEDBACK_INFO_KHR = 1000038013
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_CAPABILITIES_KHR = 1000039000
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_SESSION_PARAMETERS_CREATE_INFO_KHR = 1000039001
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_SESSION_PARAMETERS_ADD_INFO_KHR = 1000039002
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_PICTURE_INFO_KHR = 1000039003
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_DPB_SLOT_INFO_KHR = 1000039004
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_NALU_SLICE_SEGMENT_INFO_KHR = 1000039005
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_GOP_REMAINING_FRAME_INFO_KHR = 1000039006
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_PROFILE_INFO_KHR = 1000039007
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_RATE_CONTROL_INFO_KHR = 1000039009
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_RATE_CONTROL_LAYER_INFO_KHR = 1000039010
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_SESSION_CREATE_INFO_KHR = 1000039011
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_QUALITY_LEVEL_PROPERTIES_KHR = 1000039012
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_SESSION_PARAMETERS_GET_INFO_KHR = 1000039013
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_SESSION_PARAMETERS_FEEDBACK_INFO_KHR = 1000039014
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H264_CAPABILITIES_KHR = 1000040000
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H264_PICTURE_INFO_KHR = 1000040001
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H264_PROFILE_INFO_KHR = 1000040003
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H264_SESSION_PARAMETERS_CREATE_INFO_KHR = 1000040004
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H264_SESSION_PARAMETERS_ADD_INFO_KHR = 1000040005
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H264_DPB_SLOT_INFO_KHR = 1000040006
M.VK_STRUCTURE_TYPE_TEXTURE_LOD_GATHER_FORMAT_PROPERTIES_AMD = 1000041000
M.VK_RENDERING_CONTENTS_SECONDARY_COMMAND_BUFFERS_BIT_KHR = 1
M.VK_RENDERING_SUSPENDING_BIT_KHR = 2
M.VK_RENDERING_RESUMING_BIT_KHR = 4
M.VK_STRUCTURE_TYPE_STREAM_DESCRIPTOR_SURFACE_CREATE_INFO_GGP = 1000049000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CORNER_SAMPLED_IMAGE_FEATURES_NV = 1000050000
M.VK_STRUCTURE_TYPE_PRIVATE_VENDOR_INFO_PLACEHOLDER_OFFSET_0_NV = 1000051000
M.VK_FORMAT_PVRTC1_2BPP_UNORM_BLOCK_IMG = 1000054000
M.VK_FORMAT_PVRTC1_4BPP_UNORM_BLOCK_IMG = 1000054001
M.VK_FORMAT_PVRTC2_2BPP_UNORM_BLOCK_IMG = 1000054002
M.VK_FORMAT_PVRTC2_4BPP_UNORM_BLOCK_IMG = 1000054003
M.VK_FORMAT_PVRTC1_2BPP_SRGB_BLOCK_IMG = 1000054004
M.VK_FORMAT_PVRTC1_4BPP_SRGB_BLOCK_IMG = 1000054005
M.VK_FORMAT_PVRTC2_2BPP_SRGB_BLOCK_IMG = 1000054006
M.VK_FORMAT_PVRTC2_4BPP_SRGB_BLOCK_IMG = 1000054007
M.VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO_NV = 1000056000
M.VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO_NV = 1000056001
M.VK_STRUCTURE_TYPE_IMPORT_MEMORY_WIN32_HANDLE_INFO_NV = 1000057000
M.VK_STRUCTURE_TYPE_EXPORT_MEMORY_WIN32_HANDLE_INFO_NV = 1000057001
M.VK_STRUCTURE_TYPE_WIN32_KEYED_MUTEX_ACQUIRE_RELEASE_INFO_NV = 1000058000
M.VK_PEER_MEMORY_FEATURE_COPY_SRC_BIT_KHR = 1
M.VK_PEER_MEMORY_FEATURE_COPY_DST_BIT_KHR = 2
M.VK_PEER_MEMORY_FEATURE_GENERIC_SRC_BIT_KHR = 4
M.VK_PEER_MEMORY_FEATURE_GENERIC_DST_BIT_KHR = 8
M.VK_MEMORY_ALLOCATE_DEVICE_MASK_BIT_KHR = 1
M.VK_STRUCTURE_TYPE_VALIDATION_FLAGS_EXT = 1000061000
M.VK_STRUCTURE_TYPE_VI_SURFACE_CREATE_INFO_NN = 1000062000
M.VK_STRUCTURE_TYPE_IMAGE_VIEW_ASTC_DECODE_MODE_EXT = 1000067000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ASTC_DECODE_FEATURES_EXT = 1000067001
M.VK_PIPELINE_ROBUSTNESS_BUFFER_BEHAVIOR_DEVICE_DEFAULT_EXT = 0
M.VK_PIPELINE_ROBUSTNESS_BUFFER_BEHAVIOR_DISABLED_EXT = 1
M.VK_PIPELINE_ROBUSTNESS_BUFFER_BEHAVIOR_ROBUST_BUFFER_ACCESS_EXT = 2
M.VK_PIPELINE_ROBUSTNESS_BUFFER_BEHAVIOR_ROBUST_BUFFER_ACCESS_2_EXT = 3
M.VK_PIPELINE_ROBUSTNESS_IMAGE_BEHAVIOR_DEVICE_DEFAULT_EXT = 0
M.VK_PIPELINE_ROBUSTNESS_IMAGE_BEHAVIOR_DISABLED_EXT = 1
M.VK_PIPELINE_ROBUSTNESS_IMAGE_BEHAVIOR_ROBUST_IMAGE_ACCESS_EXT = 2
M.VK_PIPELINE_ROBUSTNESS_IMAGE_BEHAVIOR_ROBUST_IMAGE_ACCESS_2_EXT = 3
M.VK_MAX_DEVICE_GROUP_SIZE_KHR = 32
M.VK_LUID_SIZE_KHR = 8
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT_KHR = 1
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR = 2
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR = 4
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT_KHR = 8
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_KMT_BIT_KHR = 16
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_HEAP_BIT_KHR = 32
M.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT_KHR = 64
M.VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT_KHR = 1
M.VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT_KHR = 2
M.VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT_KHR = 4
M.VK_QUEUE_FAMILY_EXTERNAL_KHR = 0xFFFFFFFFFFFFFFFEULL
M.VK_STRUCTURE_TYPE_IMPORT_MEMORY_WIN32_HANDLE_INFO_KHR = 1000073000
M.VK_STRUCTURE_TYPE_EXPORT_MEMORY_WIN32_HANDLE_INFO_KHR = 1000073001
M.VK_STRUCTURE_TYPE_MEMORY_WIN32_HANDLE_PROPERTIES_KHR = 1000073002
M.VK_STRUCTURE_TYPE_MEMORY_GET_WIN32_HANDLE_INFO_KHR = 1000073003
M.VK_STRUCTURE_TYPE_IMPORT_MEMORY_FD_INFO_KHR = 1000074000
M.VK_STRUCTURE_TYPE_MEMORY_FD_PROPERTIES_KHR = 1000074001
M.VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR = 1000074002
M.VK_STRUCTURE_TYPE_WIN32_KEYED_MUTEX_ACQUIRE_RELEASE_INFO_KHR = 1000075000
M.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT_KHR = 1
M.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR = 2
M.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR = 4
M.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE_BIT_KHR = 8
M.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_SYNC_FD_BIT_KHR = 16
M.VK_EXTERNAL_SEMAPHORE_FEATURE_EXPORTABLE_BIT_KHR = 1
M.VK_EXTERNAL_SEMAPHORE_FEATURE_IMPORTABLE_BIT_KHR = 2
M.VK_SEMAPHORE_IMPORT_TEMPORARY_BIT_KHR = 1
M.VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR = 1000078000
M.VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR = 1000078001
M.VK_STRUCTURE_TYPE_D3D12_FENCE_SUBMIT_INFO_KHR = 1000078002
M.VK_STRUCTURE_TYPE_SEMAPHORE_GET_WIN32_HANDLE_INFO_KHR = 1000078003
M.VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_FD_INFO_KHR = 1000079000
M.VK_STRUCTURE_TYPE_SEMAPHORE_GET_FD_INFO_KHR = 1000079001
M.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_CONDITIONAL_RENDERING_INFO_EXT = 1000081000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CONDITIONAL_RENDERING_FEATURES_EXT = 1000081001
M.VK_STRUCTURE_TYPE_CONDITIONAL_RENDERING_BEGIN_INFO_EXT = 1000081002
M.VK_STRUCTURE_TYPE_PRESENT_REGIONS_KHR = 1000084000
M.VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET_KHR = 0
M.VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_KHR_EXT = 1000085000
M.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_W_SCALING_STATE_CREATE_INFO_NV = 1000087000
M.VK_DYNAMIC_STATE_VIEWPORT_W_SCALING_NV = 1000087000
M.VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_2_EXT = 1000090000
M.VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES2_EXT = 1000090000
M.VK_STRUCTURE_TYPE_DISPLAY_POWER_INFO_EXT = 1000091000
M.VK_STRUCTURE_TYPE_DEVICE_EVENT_INFO_EXT = 1000091001
M.VK_STRUCTURE_TYPE_DISPLAY_EVENT_INFO_EXT = 1000091002
M.VK_STRUCTURE_TYPE_SWAPCHAIN_COUNTER_CREATE_INFO_EXT = 1000091003
M.VK_STRUCTURE_TYPE_PRESENT_TIMES_INFO_GOOGLE = 1000092000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PER_VIEW_ATTRIBUTES_PROPERTIES_NVX = 1000097000
M.VK_STRUCTURE_TYPE_MULTIVIEW_PER_VIEW_ATTRIBUTES_INFO_NVX = 1000044009
M.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_SWIZZLE_STATE_CREATE_INFO_NV = 1000098000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DISCARD_RECTANGLE_PROPERTIES_EXT = 1000099000
M.VK_STRUCTURE_TYPE_PIPELINE_DISCARD_RECTANGLE_STATE_CREATE_INFO_EXT = 1000099001
M.VK_DYNAMIC_STATE_DISCARD_RECTANGLE_EXT = 1000099000
M.VK_DYNAMIC_STATE_DISCARD_RECTANGLE_ENABLE_EXT = 1000099001
M.VK_DYNAMIC_STATE_DISCARD_RECTANGLE_MODE_EXT = 1000099002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CONSERVATIVE_RASTERIZATION_PROPERTIES_EXT = 1000101000
M.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_CONSERVATIVE_STATE_CREATE_INFO_EXT = 1000101001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_CLIP_ENABLE_FEATURES_EXT = 1000102000
M.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_DEPTH_CLIP_STATE_CREATE_INFO_EXT = 1000102001
M.VK_COLOR_SPACE_DISPLAY_P3_NONLINEAR_EXT = 1000104001
M.VK_COLOR_SPACE_EXTENDED_SRGB_LINEAR_EXT = 1000104002
M.VK_COLOR_SPACE_DISPLAY_P3_LINEAR_EXT = 1000104003
M.VK_COLOR_SPACE_DCI_P3_NONLINEAR_EXT = 1000104004
M.VK_COLOR_SPACE_BT709_LINEAR_EXT = 1000104005
M.VK_COLOR_SPACE_BT709_NONLINEAR_EXT = 1000104006
M.VK_COLOR_SPACE_BT2020_LINEAR_EXT = 1000104007
M.VK_COLOR_SPACE_HDR10_ST2084_EXT = 1000104008
M.VK_COLOR_SPACE_DOLBYVISION_EXT = 1000104009
M.VK_COLOR_SPACE_HDR10_HLG_EXT = 1000104010
M.VK_COLOR_SPACE_ADOBERGB_LINEAR_EXT = 1000104011
M.VK_COLOR_SPACE_ADOBERGB_NONLINEAR_EXT = 1000104012
M.VK_COLOR_SPACE_PASS_THROUGH_EXT = 1000104013
M.VK_COLOR_SPACE_EXTENDED_SRGB_NONLINEAR_EXT = 1000104014
M.VK_COLOR_SPACE_DCI_P3_LINEAR_EXT = 1000104003
M.VK_STRUCTURE_TYPE_HDR_METADATA_EXT = 1000105000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RELAXED_LINE_RASTERIZATION_FEATURES_IMG = 1000110000
M.VK_STRUCTURE_TYPE_SHARED_PRESENT_SURFACE_CAPABILITIES_KHR = 1000111000
M.VK_PRESENT_MODE_SHARED_DEMAND_REFRESH_KHR = 1000111000
M.VK_PRESENT_MODE_SHARED_CONTINUOUS_REFRESH_KHR = 1000111001
M.VK_IMAGE_LAYOUT_SHARED_PRESENT_KHR = 1000111000
M.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT_KHR = 1
M.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR = 2
M.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR = 4
M.VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT_KHR = 8
M.VK_EXTERNAL_FENCE_FEATURE_EXPORTABLE_BIT_KHR = 1
M.VK_EXTERNAL_FENCE_FEATURE_IMPORTABLE_BIT_KHR = 2
M.VK_FENCE_IMPORT_TEMPORARY_BIT_KHR = 1
M.VK_STRUCTURE_TYPE_IMPORT_FENCE_WIN32_HANDLE_INFO_KHR = 1000114000
M.VK_STRUCTURE_TYPE_EXPORT_FENCE_WIN32_HANDLE_INFO_KHR = 1000114001
M.VK_STRUCTURE_TYPE_FENCE_GET_WIN32_HANDLE_INFO_KHR = 1000114002
M.VK_STRUCTURE_TYPE_IMPORT_FENCE_FD_INFO_KHR = 1000115000
M.VK_STRUCTURE_TYPE_FENCE_GET_FD_INFO_KHR = 1000115001
M.VK_QUERY_TYPE_PERFORMANCE_QUERY_KHR = 1000116000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PERFORMANCE_QUERY_FEATURES_KHR = 1000116000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PERFORMANCE_QUERY_PROPERTIES_KHR = 1000116001
M.VK_STRUCTURE_TYPE_QUERY_POOL_PERFORMANCE_CREATE_INFO_KHR = 1000116002
M.VK_STRUCTURE_TYPE_PERFORMANCE_QUERY_SUBMIT_INFO_KHR = 1000116003
M.VK_STRUCTURE_TYPE_ACQUIRE_PROFILING_LOCK_INFO_KHR = 1000116004
M.VK_STRUCTURE_TYPE_PERFORMANCE_COUNTER_KHR = 1000116005
M.VK_STRUCTURE_TYPE_PERFORMANCE_COUNTER_DESCRIPTION_KHR = 1000116006
M.VK_STRUCTURE_TYPE_PERFORMANCE_QUERY_RESERVATION_INFO_KHR = 1000116007
M.VK_POINT_CLIPPING_BEHAVIOR_ALL_CLIP_PLANES_KHR = 0
M.VK_POINT_CLIPPING_BEHAVIOR_USER_CLIP_PLANES_ONLY_KHR = 1
M.VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT_KHR = 0
M.VK_TESSELLATION_DOMAIN_ORIGIN_LOWER_LEFT_KHR = 1
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SURFACE_INFO_2_KHR = 1000119000
M.VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_2_KHR = 1000119001
M.VK_STRUCTURE_TYPE_SURFACE_FORMAT_2_KHR = 1000119002
M.VK_STRUCTURE_TYPE_DISPLAY_PROPERTIES_2_KHR = 1000121000
M.VK_STRUCTURE_TYPE_DISPLAY_PLANE_PROPERTIES_2_KHR = 1000121001
M.VK_STRUCTURE_TYPE_DISPLAY_MODE_PROPERTIES_2_KHR = 1000121002
M.VK_STRUCTURE_TYPE_DISPLAY_PLANE_INFO_2_KHR = 1000121003
M.VK_STRUCTURE_TYPE_DISPLAY_PLANE_CAPABILITIES_2_KHR = 1000121004
M.VK_STRUCTURE_TYPE_IOS_SURFACE_CREATE_INFO_MVK = 1000122000
M.VK_STRUCTURE_TYPE_MACOS_SURFACE_CREATE_INFO_MVK = 1000123000
M.VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT = 1000128000
M.VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_TAG_INFO_EXT = 1000128001
M.VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT = 1000128002
M.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT = 1000128003
M.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT = 1000128004
M.VK_OBJECT_TYPE_DEBUG_UTILS_MESSENGER_EXT = 1000128000
M.VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_USAGE_ANDROID = 1000129000
M.VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_PROPERTIES_ANDROID = 1000129001
M.VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_FORMAT_PROPERTIES_ANDROID = 1000129002
M.VK_STRUCTURE_TYPE_IMPORT_ANDROID_HARDWARE_BUFFER_INFO_ANDROID = 1000129003
M.VK_STRUCTURE_TYPE_MEMORY_GET_ANDROID_HARDWARE_BUFFER_INFO_ANDROID = 1000129004
M.VK_STRUCTURE_TYPE_EXTERNAL_FORMAT_ANDROID = 1000129005
M.VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_FORMAT_PROPERTIES_2_ANDROID = 1000129006
M.VK_SAMPLER_REDUCTION_MODE_WEIGHTED_AVERAGE_EXT = 0
M.VK_SAMPLER_REDUCTION_MODE_MIN_EXT = 1
M.VK_SAMPLER_REDUCTION_MODE_MAX_EXT = 2
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ENQUEUE_FEATURES_AMDX = 1000134000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ENQUEUE_PROPERTIES_AMDX = 1000134001
M.VK_STRUCTURE_TYPE_EXECUTION_GRAPH_PIPELINE_SCRATCH_SIZE_AMDX = 1000134002
M.VK_STRUCTURE_TYPE_EXECUTION_GRAPH_PIPELINE_CREATE_INFO_AMDX = 1000134003
M.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_NODE_CREATE_INFO_AMDX = 1000134004
M.VK_PIPELINE_BIND_POINT_EXECUTION_GRAPH_AMDX = 1000134000
M.VK_STRUCTURE_TYPE_TEXEL_BUFFER_DESCRIPTOR_INFO_EXT = 1000135000
M.VK_STRUCTURE_TYPE_IMAGE_DESCRIPTOR_INFO_EXT = 1000135001
M.VK_STRUCTURE_TYPE_RESOURCE_DESCRIPTOR_INFO_EXT = 1000135002
M.VK_STRUCTURE_TYPE_BIND_HEAP_INFO_EXT = 1000135003
M.VK_STRUCTURE_TYPE_PUSH_DATA_INFO_EXT = 1000135004
M.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_AND_BINDING_MAPPING_EXT = 1000135005
M.VK_STRUCTURE_TYPE_SHADER_DESCRIPTOR_SET_AND_BINDING_MAPPING_INFO_EXT = 1000135006
M.VK_STRUCTURE_TYPE_OPAQUE_CAPTURE_DATA_CREATE_INFO_EXT = 1000135007
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_HEAP_PROPERTIES_EXT = 1000135008
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_HEAP_FEATURES_EXT = 1000135009
M.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_DESCRIPTOR_HEAP_INFO_EXT = 1000135010
M.VK_STRUCTURE_TYPE_SAMPLER_CUSTOM_BORDER_COLOR_INDEX_CREATE_INFO_EXT = 1000135011
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_PUSH_DATA_EXT = 1000135000
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_PUSH_DATA_SEQUENCE_INDEX_EXT = 1000135001
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_PUSH_DATA_NV = 1000135000
M.VK_STRUCTURE_TYPE_INDIRECT_COMMANDS_LAYOUT_PUSH_DATA_TOKEN_NV = 1000135012
M.VK_STRUCTURE_TYPE_SUBSAMPLED_IMAGE_FORMAT_PROPERTIES_EXT = 1000135013
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_HEAP_TENSOR_PROPERTIES_ARM = 1000135014
M.VK_STRUCTURE_TYPE_ATTACHMENT_SAMPLE_COUNT_INFO_AMD = 1000044008
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_BFLOAT16_FEATURES_KHR = 1000141000
M.VK_COMPONENT_TYPE_BFLOAT16_KHR = 1000141000
M.VK_STRUCTURE_TYPE_SAMPLE_LOCATIONS_INFO_EXT = 1000143000
M.VK_STRUCTURE_TYPE_RENDER_PASS_SAMPLE_LOCATIONS_BEGIN_INFO_EXT = 1000143001
M.VK_STRUCTURE_TYPE_PIPELINE_SAMPLE_LOCATIONS_STATE_CREATE_INFO_EXT = 1000143002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLE_LOCATIONS_PROPERTIES_EXT = 1000143003
M.VK_STRUCTURE_TYPE_MULTISAMPLE_PROPERTIES_EXT = 1000143004
M.VK_DYNAMIC_STATE_SAMPLE_LOCATIONS_EXT = 1000143000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_FEATURES_EXT = 1000148000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_PROPERTIES_EXT = 1000148001
M.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_ADVANCED_STATE_CREATE_INFO_EXT = 1000148002
M.VK_BLEND_OP_ZERO_EXT = 1000148000
M.VK_BLEND_OP_SRC_EXT = 1000148001
M.VK_BLEND_OP_DST_EXT = 1000148002
M.VK_BLEND_OP_SRC_OVER_EXT = 1000148003
M.VK_BLEND_OP_DST_OVER_EXT = 1000148004
M.VK_BLEND_OP_SRC_IN_EXT = 1000148005
M.VK_BLEND_OP_DST_IN_EXT = 1000148006
M.VK_BLEND_OP_SRC_OUT_EXT = 1000148007
M.VK_BLEND_OP_DST_OUT_EXT = 1000148008
M.VK_BLEND_OP_SRC_ATOP_EXT = 1000148009
M.VK_BLEND_OP_DST_ATOP_EXT = 1000148010
M.VK_BLEND_OP_XOR_EXT = 1000148011
M.VK_BLEND_OP_MULTIPLY_EXT = 1000148012
M.VK_BLEND_OP_SCREEN_EXT = 1000148013
M.VK_BLEND_OP_OVERLAY_EXT = 1000148014
M.VK_BLEND_OP_DARKEN_EXT = 1000148015
M.VK_BLEND_OP_LIGHTEN_EXT = 1000148016
M.VK_BLEND_OP_COLORDODGE_EXT = 1000148017
M.VK_BLEND_OP_COLORBURN_EXT = 1000148018
M.VK_BLEND_OP_HARDLIGHT_EXT = 1000148019
M.VK_BLEND_OP_SOFTLIGHT_EXT = 1000148020
M.VK_BLEND_OP_DIFFERENCE_EXT = 1000148021
M.VK_BLEND_OP_EXCLUSION_EXT = 1000148022
M.VK_BLEND_OP_INVERT_EXT = 1000148023
M.VK_BLEND_OP_INVERT_RGB_EXT = 1000148024
M.VK_BLEND_OP_LINEARDODGE_EXT = 1000148025
M.VK_BLEND_OP_LINEARBURN_EXT = 1000148026
M.VK_BLEND_OP_VIVIDLIGHT_EXT = 1000148027
M.VK_BLEND_OP_LINEARLIGHT_EXT = 1000148028
M.VK_BLEND_OP_PINLIGHT_EXT = 1000148029
M.VK_BLEND_OP_HARDMIX_EXT = 1000148030
M.VK_BLEND_OP_HSL_HUE_EXT = 1000148031
M.VK_BLEND_OP_HSL_SATURATION_EXT = 1000148032
M.VK_BLEND_OP_HSL_COLOR_EXT = 1000148033
M.VK_BLEND_OP_HSL_LUMINOSITY_EXT = 1000148034
M.VK_BLEND_OP_PLUS_EXT = 1000148035
M.VK_BLEND_OP_PLUS_CLAMPED_EXT = 1000148036
M.VK_BLEND_OP_PLUS_CLAMPED_ALPHA_EXT = 1000148037
M.VK_BLEND_OP_PLUS_DARKER_EXT = 1000148038
M.VK_BLEND_OP_MINUS_EXT = 1000148039
M.VK_BLEND_OP_MINUS_CLAMPED_EXT = 1000148040
M.VK_BLEND_OP_CONTRAST_EXT = 1000148041
M.VK_BLEND_OP_INVERT_OVG_EXT = 1000148042
M.VK_BLEND_OP_RED_EXT = 1000148043
M.VK_BLEND_OP_GREEN_EXT = 1000148044
M.VK_BLEND_OP_BLUE_EXT = 1000148045
M.VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_TO_COLOR_STATE_CREATE_INFO_NV = 1000149000
M.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_ACCELERATION_STRUCTURE_KHR = 1000150007
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_BUILD_GEOMETRY_INFO_KHR = 1000150000
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_DEVICE_ADDRESS_INFO_KHR = 1000150002
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_AABBS_DATA_KHR = 1000150003
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_INSTANCES_DATA_KHR = 1000150004
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_TRIANGLES_DATA_KHR = 1000150005
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_KHR = 1000150006
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_VERSION_INFO_KHR = 1000150009
M.VK_STRUCTURE_TYPE_COPY_ACCELERATION_STRUCTURE_INFO_KHR = 1000150010
M.VK_STRUCTURE_TYPE_COPY_ACCELERATION_STRUCTURE_TO_MEMORY_INFO_KHR = 1000150011
M.VK_STRUCTURE_TYPE_COPY_MEMORY_TO_ACCELERATION_STRUCTURE_INFO_KHR = 1000150012
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ACCELERATION_STRUCTURE_FEATURES_KHR = 1000150013
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ACCELERATION_STRUCTURE_PROPERTIES_KHR = 1000150014
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_KHR = 1000150017
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_BUILD_SIZES_INFO_KHR = 1000150020
M.VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR = 1000150000
M.VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_KHR = 1000150000
M.VK_QUERY_TYPE_ACCELERATION_STRUCTURE_SERIALIZATION_SIZE_KHR = 1000150001
M.VK_OBJECT_TYPE_ACCELERATION_STRUCTURE_KHR = 1000150000
M.VK_INDEX_TYPE_NONE_KHR = 1000165000
M.VK_DEBUG_REPORT_OBJECT_TYPE_ACCELERATION_STRUCTURE_KHR_EXT = 1000150000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PIPELINE_FEATURES_KHR = 1000347000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PIPELINE_PROPERTIES_KHR = 1000347001
M.VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CREATE_INFO_KHR = 1000150015
M.VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_KHR = 1000150016
M.VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_INTERFACE_CREATE_INFO_KHR = 1000150018
M.VK_PIPELINE_BIND_POINT_RAY_TRACING_KHR = 1000165000
M.VK_DYNAMIC_STATE_RAY_TRACING_PIPELINE_STACK_SIZE_KHR = 1000347000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_QUERY_FEATURES_KHR = 1000348013
M.VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_MODULATION_STATE_CREATE_INFO_NV = 1000152000
M.VK_STRUCTURE_TYPE_ATTACHMENT_SAMPLE_COUNT_INFO_NV = 1000044008
M.VK_POLYGON_MODE_FILL_RECTANGLE_NV = 1000153000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_FEATURES_NV = 1000154000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_PROPERTIES_NV = 1000154001
M.VK_SAMPLER_YCBCR_MODEL_CONVERSION_RGB_IDENTITY_KHR = 0
M.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_IDENTITY_KHR = 1
M.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_709_KHR = 2
M.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_601_KHR = 3
M.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_2020_KHR = 4
M.VK_SAMPLER_YCBCR_RANGE_ITU_FULL_KHR = 0
M.VK_SAMPLER_YCBCR_RANGE_ITU_NARROW_KHR = 1
M.VK_CHROMA_LOCATION_COSITED_EVEN_KHR = 0
M.VK_CHROMA_LOCATION_MIDPOINT_KHR = 1
M.VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_KHR_EXT = 1000156000
M.VK_ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT = -1000158000
M.VK_STRUCTURE_TYPE_DRM_FORMAT_MODIFIER_PROPERTIES_LIST_EXT = 1000158000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_DRM_FORMAT_MODIFIER_INFO_EXT = 1000158002
M.VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_LIST_CREATE_INFO_EXT = 1000158003
M.VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_EXPLICIT_CREATE_INFO_EXT = 1000158004
M.VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_PROPERTIES_EXT = 1000158005
M.VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT = 1000158000
M.VK_STRUCTURE_TYPE_DRM_FORMAT_MODIFIER_PROPERTIES_LIST_2_EXT = 1000158006
M.VK_STRUCTURE_TYPE_VALIDATION_CACHE_CREATE_INFO_EXT = 1000160000
M.VK_STRUCTURE_TYPE_SHADER_MODULE_VALIDATION_CACHE_CREATE_INFO_EXT = 1000160001
M.VK_OBJECT_TYPE_VALIDATION_CACHE_EXT = 1000160000
M.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT_EXT = 1
M.VK_DESCRIPTOR_BINDING_UPDATE_UNUSED_WHILE_PENDING_BIT_EXT = 2
M.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT_EXT = 4
M.VK_DESCRIPTOR_BINDING_VARIABLE_DESCRIPTOR_COUNT_BIT_EXT = 8
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PORTABILITY_SUBSET_FEATURES_KHR = 1000163000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PORTABILITY_SUBSET_PROPERTIES_KHR = 1000163001
M.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_SHADING_RATE_IMAGE_STATE_CREATE_INFO_NV = 1000164000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADING_RATE_IMAGE_FEATURES_NV = 1000164001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADING_RATE_IMAGE_PROPERTIES_NV = 1000164002
M.VK_DYNAMIC_STATE_VIEWPORT_SHADING_RATE_PALETTE_NV = 1000164004
M.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_COARSE_SAMPLE_ORDER_STATE_CREATE_INFO_NV = 1000164005
M.VK_DYNAMIC_STATE_VIEWPORT_COARSE_SAMPLE_ORDER_NV = 1000164006
M.VK_SHADER_UNUSED_NV = 0xFFFFFFFFFFFFFFFFULL
M.VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CREATE_INFO_NV = 1000165000
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_NV = 1000165001
M.VK_STRUCTURE_TYPE_GEOMETRY_NV = 1000165003
M.VK_STRUCTURE_TYPE_GEOMETRY_TRIANGLES_NV = 1000165004
M.VK_STRUCTURE_TYPE_GEOMETRY_AABB_NV = 1000165005
M.VK_STRUCTURE_TYPE_BIND_ACCELERATION_STRUCTURE_MEMORY_INFO_NV = 1000165006
M.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_ACCELERATION_STRUCTURE_NV = 1000165007
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_INFO_NV = 1000165008
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PROPERTIES_NV = 1000165009
M.VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_NV = 1000165011
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_INFO_NV = 1000165012
M.VK_PIPELINE_BIND_POINT_RAY_TRACING_NV = 1000165000
M.VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_NV = 1000165000
M.VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_NV = 1000165000
M.VK_OBJECT_TYPE_ACCELERATION_STRUCTURE_NV = 1000165000
M.VK_INDEX_TYPE_NONE_NV = 1000165000
M.VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV = 0
M.VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_NV = 1
M.VK_RAY_TRACING_SHADER_GROUP_TYPE_PROCEDURAL_HIT_GROUP_NV = 2
M.VK_GEOMETRY_TYPE_TRIANGLES_NV = 0
M.VK_GEOMETRY_TYPE_AABBS_NV = 1
M.VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_NV = 0
M.VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_NV = 1
M.VK_GEOMETRY_OPAQUE_BIT_NV = 1
M.VK_GEOMETRY_NO_DUPLICATE_ANY_HIT_INVOCATION_BIT_NV = 2
M.VK_GEOMETRY_INSTANCE_TRIANGLE_CULL_DISABLE_BIT_NV = 1
M.VK_GEOMETRY_INSTANCE_TRIANGLE_FRONT_COUNTERCLOCKWISE_BIT_NV = 2
M.VK_GEOMETRY_INSTANCE_FORCE_OPAQUE_BIT_NV = 4
M.VK_GEOMETRY_INSTANCE_FORCE_NO_OPAQUE_BIT_NV = 8
M.VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_UPDATE_BIT_NV = 1
M.VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_COMPACTION_BIT_NV = 2
M.VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_NV = 4
M.VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_BUILD_BIT_NV = 8
M.VK_BUILD_ACCELERATION_STRUCTURE_LOW_MEMORY_BIT_NV = 16
M.VK_COPY_ACCELERATION_STRUCTURE_MODE_CLONE_NV = 0
M.VK_COPY_ACCELERATION_STRUCTURE_MODE_COMPACT_NV = 1
M.VK_DEBUG_REPORT_OBJECT_TYPE_ACCELERATION_STRUCTURE_NV_EXT = 1000165000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_REPRESENTATIVE_FRAGMENT_TEST_FEATURES_NV = 1000166000
M.VK_STRUCTURE_TYPE_PIPELINE_REPRESENTATIVE_FRAGMENT_TEST_STATE_CREATE_INFO_NV = 1000166001
M.VK_FILTER_CUBIC_EXT = 1000015000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_VIEW_IMAGE_FORMAT_INFO_EXT = 1000170000
M.VK_STRUCTURE_TYPE_FILTER_CUBIC_IMAGE_VIEW_IMAGE_FORMAT_PROPERTIES_EXT = 1000170001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_CONVERSION_FEATURES_QCOM = 1000172000
M.VK_QUEUE_GLOBAL_PRIORITY_LOW_EXT = 128
M.VK_QUEUE_GLOBAL_PRIORITY_MEDIUM_EXT = 256
M.VK_QUEUE_GLOBAL_PRIORITY_HIGH_EXT = 512
M.VK_QUEUE_GLOBAL_PRIORITY_REALTIME_EXT = 1024
M.VK_STRUCTURE_TYPE_IMPORT_MEMORY_HOST_POINTER_INFO_EXT = 1000178000
M.VK_STRUCTURE_TYPE_MEMORY_HOST_POINTER_PROPERTIES_EXT = 1000178001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_MEMORY_HOST_PROPERTIES_EXT = 1000178002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_CLOCK_FEATURES_KHR = 1000181000
M.VK_STRUCTURE_TYPE_PIPELINE_COMPILER_CONTROL_CREATE_INFO_AMD = 1000183000
M.VK_TIME_DOMAIN_DEVICE_EXT = 0
M.VK_TIME_DOMAIN_CLOCK_MONOTONIC_EXT = 1
M.VK_TIME_DOMAIN_CLOCK_MONOTONIC_RAW_EXT = 2
M.VK_TIME_DOMAIN_QUERY_PERFORMANCE_COUNTER_EXT = 3
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_CORE_PROPERTIES_AMD = 1000185000
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H265_CAPABILITIES_KHR = 1000187000
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H265_SESSION_PARAMETERS_CREATE_INFO_KHR = 1000187001
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H265_SESSION_PARAMETERS_ADD_INFO_KHR = 1000187002
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H265_PROFILE_INFO_KHR = 1000187003
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H265_PICTURE_INFO_KHR = 1000187004
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H265_DPB_SLOT_INFO_KHR = 1000187005
M.VK_MAX_GLOBAL_PRIORITY_SIZE_KHR = 16
M.VK_QUEUE_GLOBAL_PRIORITY_LOW_KHR = 128
M.VK_QUEUE_GLOBAL_PRIORITY_MEDIUM_KHR = 256
M.VK_QUEUE_GLOBAL_PRIORITY_HIGH_KHR = 512
M.VK_QUEUE_GLOBAL_PRIORITY_REALTIME_KHR = 1024
M.VK_STRUCTURE_TYPE_DEVICE_MEMORY_OVERALLOCATION_CREATE_INFO_AMD = 1000189000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_PROPERTIES_EXT = 1000190000
M.VK_STRUCTURE_TYPE_PRESENT_FRAME_TOKEN_GGP = 1000191000
M.VK_PIPELINE_CREATION_FEEDBACK_VALID_BIT_EXT = 1
M.VK_PIPELINE_CREATION_FEEDBACK_APPLICATION_PIPELINE_CACHE_HIT_BIT_EXT = 2
M.VK_PIPELINE_CREATION_FEEDBACK_BASE_PIPELINE_ACCELERATION_BIT_EXT = 4
M.VK_MAX_DRIVER_NAME_SIZE_KHR = 256
M.VK_MAX_DRIVER_INFO_SIZE_KHR = 256
M.VK_DRIVER_ID_AMD_PROPRIETARY_KHR = 1
M.VK_DRIVER_ID_AMD_OPEN_SOURCE_KHR = 2
M.VK_DRIVER_ID_MESA_RADV_KHR = 3
M.VK_DRIVER_ID_NVIDIA_PROPRIETARY_KHR = 4
M.VK_DRIVER_ID_INTEL_PROPRIETARY_WINDOWS_KHR = 5
M.VK_DRIVER_ID_INTEL_OPEN_SOURCE_MESA_KHR = 6
M.VK_DRIVER_ID_IMAGINATION_PROPRIETARY_KHR = 7
M.VK_DRIVER_ID_QUALCOMM_PROPRIETARY_KHR = 8
M.VK_DRIVER_ID_ARM_PROPRIETARY_KHR = 9
M.VK_DRIVER_ID_GOOGLE_SWIFTSHADER_KHR = 10
M.VK_DRIVER_ID_GGP_PROPRIETARY_KHR = 11
M.VK_DRIVER_ID_BROADCOM_PROPRIETARY_KHR = 12
M.VK_SHADER_FLOAT_CONTROLS_INDEPENDENCE_32_BIT_ONLY_KHR = 0
M.VK_SHADER_FLOAT_CONTROLS_INDEPENDENCE_ALL_KHR = 1
M.VK_SHADER_FLOAT_CONTROLS_INDEPENDENCE_NONE_KHR = 2
M.VK_RESOLVE_MODE_NONE_KHR = 0
M.VK_RESOLVE_MODE_SAMPLE_ZERO_BIT_KHR = 1
M.VK_RESOLVE_MODE_AVERAGE_BIT_KHR = 2
M.VK_RESOLVE_MODE_MIN_BIT_KHR = 4
M.VK_RESOLVE_MODE_MAX_BIT_KHR = 8
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_FEATURES_NV = 1000202000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_PROPERTIES_NV = 1000202001
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_MESH_TASKS_NV_EXT = 1000202002
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_MESH_TASKS_COUNT_NV_EXT = 1000202003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_IMAGE_FOOTPRINT_FEATURES_NV = 1000204000
M.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_EXCLUSIVE_SCISSOR_STATE_CREATE_INFO_NV = 1000205000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXCLUSIVE_SCISSOR_FEATURES_NV = 1000205002
M.VK_DYNAMIC_STATE_EXCLUSIVE_SCISSOR_ENABLE_NV = 1000205000
M.VK_DYNAMIC_STATE_EXCLUSIVE_SCISSOR_NV = 1000205001
M.VK_STRUCTURE_TYPE_CHECKPOINT_DATA_NV = 1000206000
M.VK_STRUCTURE_TYPE_QUEUE_FAMILY_CHECKPOINT_PROPERTIES_NV = 1000206001
M.VK_STRUCTURE_TYPE_QUEUE_FAMILY_CHECKPOINT_PROPERTIES_2_NV = 1000314008
M.VK_STRUCTURE_TYPE_CHECKPOINT_DATA_2_NV = 1000314009
M.VK_SEMAPHORE_TYPE_BINARY_KHR = 0
M.VK_SEMAPHORE_TYPE_TIMELINE_KHR = 1
M.VK_SEMAPHORE_WAIT_ANY_BIT_KHR = 1
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENT_TIMING_FEATURES_EXT = 1000208000
M.VK_STRUCTURE_TYPE_SWAPCHAIN_TIMING_PROPERTIES_EXT = 1000208001
M.VK_STRUCTURE_TYPE_SWAPCHAIN_TIME_DOMAIN_PROPERTIES_EXT = 1000208002
M.VK_STRUCTURE_TYPE_PRESENT_TIMINGS_INFO_EXT = 1000208003
M.VK_STRUCTURE_TYPE_PRESENT_TIMING_INFO_EXT = 1000208004
M.VK_STRUCTURE_TYPE_PAST_PRESENTATION_TIMING_INFO_EXT = 1000208005
M.VK_STRUCTURE_TYPE_PAST_PRESENTATION_TIMING_PROPERTIES_EXT = 1000208006
M.VK_STRUCTURE_TYPE_PAST_PRESENTATION_TIMING_EXT = 1000208007
M.VK_STRUCTURE_TYPE_PRESENT_TIMING_SURFACE_CAPABILITIES_EXT = 1000208008
M.VK_STRUCTURE_TYPE_SWAPCHAIN_CALIBRATED_TIMESTAMP_INFO_EXT = 1000208009
M.VK_TIME_DOMAIN_PRESENT_STAGE_LOCAL_EXT = 1000208000
M.VK_TIME_DOMAIN_SWAPCHAIN_LOCAL_EXT = 1000208001
M.VK_ERROR_PRESENT_TIMING_QUEUE_FULL_EXT = -1000208000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_INTEGER_FUNCTIONS_2_FEATURES_INTEL = 1000209000
M.VK_STRUCTURE_TYPE_QUERY_POOL_PERFORMANCE_QUERY_CREATE_INFO_INTEL = 1000210000
M.VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO_INTEL = 1000210000
M.VK_STRUCTURE_TYPE_INITIALIZE_PERFORMANCE_API_INFO_INTEL = 1000210001
M.VK_STRUCTURE_TYPE_PERFORMANCE_MARKER_INFO_INTEL = 1000210002
M.VK_STRUCTURE_TYPE_PERFORMANCE_STREAM_MARKER_INFO_INTEL = 1000210003
M.VK_STRUCTURE_TYPE_PERFORMANCE_OVERRIDE_INFO_INTEL = 1000210004
M.VK_STRUCTURE_TYPE_PERFORMANCE_CONFIGURATION_ACQUIRE_INFO_INTEL = 1000210005
M.VK_QUERY_TYPE_PERFORMANCE_QUERY_INTEL = 1000210000
M.VK_OBJECT_TYPE_PERFORMANCE_CONFIGURATION_INTEL = 1000210000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PCI_BUS_INFO_PROPERTIES_EXT = 1000212000
M.VK_STRUCTURE_TYPE_DISPLAY_NATIVE_HDR_SURFACE_CAPABILITIES_AMD = 1000213000
M.VK_STRUCTURE_TYPE_SWAPCHAIN_DISPLAY_NATIVE_HDR_CREATE_INFO_AMD = 1000213001
M.VK_COLOR_SPACE_DISPLAY_NATIVE_AMD = 1000213000
M.VK_STRUCTURE_TYPE_IMAGEPIPE_SURFACE_CREATE_INFO_FUCHSIA = 1000214000
M.VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT = 1000217000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_FEATURES_EXT = 1000218000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_PROPERTIES_EXT = 1000218001
M.VK_STRUCTURE_TYPE_RENDER_PASS_FRAGMENT_DENSITY_MAP_CREATE_INFO_EXT = 1000218002
M.VK_IMAGE_LAYOUT_FRAGMENT_DENSITY_MAP_OPTIMAL_EXT = 1000218000
M.VK_STRUCTURE_TYPE_RENDERING_FRAGMENT_DENSITY_MAP_ATTACHMENT_INFO_EXT = 1000044007
M.VK_IMAGE_LAYOUT_FRAGMENT_SHADING_RATE_ATTACHMENT_OPTIMAL_KHR = 1000164003
M.VK_DYNAMIC_STATE_FRAGMENT_SHADING_RATE_KHR = 1000226000
M.VK_STRUCTURE_TYPE_FRAGMENT_SHADING_RATE_ATTACHMENT_INFO_KHR = 1000226000
M.VK_STRUCTURE_TYPE_PIPELINE_FRAGMENT_SHADING_RATE_STATE_CREATE_INFO_KHR = 1000226001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADING_RATE_PROPERTIES_KHR = 1000226002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADING_RATE_FEATURES_KHR = 1000226003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADING_RATE_KHR = 1000226004
M.VK_STRUCTURE_TYPE_RENDERING_FRAGMENT_SHADING_RATE_ATTACHMENT_INFO_KHR = 1000044006
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_CORE_PROPERTIES_2_AMD = 1000227000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COHERENT_MEMORY_FEATURES_AMD = 1000229000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_IMAGE_ATOMIC_INT64_FEATURES_EXT = 1000234000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_QUAD_CONTROL_FEATURES_KHR = 1000235000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_BUDGET_PROPERTIES_EXT = 1000237000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PRIORITY_FEATURES_EXT = 1000238000
M.VK_STRUCTURE_TYPE_MEMORY_PRIORITY_ALLOCATE_INFO_EXT = 1000238001
M.VK_STRUCTURE_TYPE_SURFACE_PROTECTED_CAPABILITIES_KHR = 1000239000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEDICATED_ALLOCATION_IMAGE_ALIASING_FEATURES_NV = 1000240000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES_EXT = 1000244000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_ADDRESS_FEATURES_EXT = 1000244000
M.VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_CREATE_INFO_EXT = 1000244002
M.VK_TOOL_PURPOSE_VALIDATION_BIT_EXT = 1
M.VK_TOOL_PURPOSE_PROFILING_BIT_EXT = 2
M.VK_TOOL_PURPOSE_TRACING_BIT_EXT = 4
M.VK_TOOL_PURPOSE_ADDITIONAL_FEATURES_BIT_EXT = 8
M.VK_TOOL_PURPOSE_MODIFYING_FEATURES_BIT_EXT = 16
M.VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT = 1000247000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENT_WAIT_FEATURES_KHR = 1000248000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_NV = 1000249000
M.VK_STRUCTURE_TYPE_COOPERATIVE_MATRIX_PROPERTIES_NV = 1000249001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_PROPERTIES_NV = 1000249002
M.VK_SCOPE_DEVICE_NV = 1
M.VK_SCOPE_WORKGROUP_NV = 2
M.VK_SCOPE_SUBGROUP_NV = 3
M.VK_SCOPE_QUEUE_FAMILY_NV = 5
M.VK_COMPONENT_TYPE_FLOAT16_NV = 0
M.VK_COMPONENT_TYPE_FLOAT32_NV = 1
M.VK_COMPONENT_TYPE_FLOAT64_NV = 2
M.VK_COMPONENT_TYPE_SINT8_NV = 3
M.VK_COMPONENT_TYPE_SINT16_NV = 4
M.VK_COMPONENT_TYPE_SINT32_NV = 5
M.VK_COMPONENT_TYPE_SINT64_NV = 6
M.VK_COMPONENT_TYPE_UINT8_NV = 7
M.VK_COMPONENT_TYPE_UINT16_NV = 8
M.VK_COMPONENT_TYPE_UINT32_NV = 9
M.VK_COMPONENT_TYPE_UINT64_NV = 10
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COVERAGE_REDUCTION_MODE_FEATURES_NV = 1000250000
M.VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_REDUCTION_STATE_CREATE_INFO_NV = 1000250001
M.VK_STRUCTURE_TYPE_FRAMEBUFFER_MIXED_SAMPLES_COMBINATION_NV = 1000250002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADER_INTERLOCK_FEATURES_EXT = 1000251000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_YCBCR_IMAGE_ARRAYS_FEATURES_EXT = 1000252000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROVOKING_VERTEX_FEATURES_EXT = 1000254000
M.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_PROVOKING_VERTEX_STATE_CREATE_INFO_EXT = 1000254001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROVOKING_VERTEX_PROPERTIES_EXT = 1000254002
M.VK_STRUCTURE_TYPE_SURFACE_FULL_SCREEN_EXCLUSIVE_INFO_EXT = 1000255000
M.VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_FULL_SCREEN_EXCLUSIVE_EXT = 1000255002
M.VK_ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT = -1000255000
M.VK_STRUCTURE_TYPE_SURFACE_FULL_SCREEN_EXCLUSIVE_WIN32_INFO_EXT = 1000255001
M.VK_STRUCTURE_TYPE_HEADLESS_SURFACE_CREATE_INFO_EXT = 1000256000
M.VK_LINE_RASTERIZATION_MODE_DEFAULT_EXT = 0
M.VK_LINE_RASTERIZATION_MODE_RECTANGULAR_EXT = 1
M.VK_LINE_RASTERIZATION_MODE_BRESENHAM_EXT = 2
M.VK_LINE_RASTERIZATION_MODE_RECTANGULAR_SMOOTH_EXT = 3
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ATOMIC_FLOAT_FEATURES_EXT = 1000260000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTENDED_DYNAMIC_STATE_FEATURES_EXT = 1000267000
M.VK_OBJECT_TYPE_DEFERRED_OPERATION_KHR = 1000268000
M.VK_THREAD_IDLE_KHR = 1000268000
M.VK_THREAD_DONE_KHR = 1000268001
M.VK_OPERATION_DEFERRED_KHR = 1000268002
M.VK_OPERATION_NOT_DEFERRED_KHR = 1000268003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_EXECUTABLE_PROPERTIES_FEATURES_KHR = 1000269000
M.VK_STRUCTURE_TYPE_PIPELINE_INFO_KHR = 1000269001
M.VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_PROPERTIES_KHR = 1000269002
M.VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_INFO_KHR = 1000269003
M.VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_STATISTIC_KHR = 1000269004
M.VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_INTERNAL_REPRESENTATION_KHR = 1000269005
M.VK_HOST_IMAGE_COPY_MEMCPY_BIT_EXT = 1
M.VK_HOST_IMAGE_COPY_MEMCPY_EXT = 1
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAP_MEMORY_PLACED_FEATURES_EXT = 1000272000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAP_MEMORY_PLACED_PROPERTIES_EXT = 1000272001
M.VK_STRUCTURE_TYPE_MEMORY_MAP_PLACED_INFO_EXT = 1000272002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ATOMIC_FLOAT_2_FEATURES_EXT = 1000273000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEVICE_GENERATED_COMMANDS_PROPERTIES_NV = 1000277000
M.VK_STRUCTURE_TYPE_GRAPHICS_SHADER_GROUP_CREATE_INFO_NV = 1000277001
M.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_SHADER_GROUPS_CREATE_INFO_NV = 1000277002
M.VK_STRUCTURE_TYPE_INDIRECT_COMMANDS_LAYOUT_TOKEN_NV = 1000277003
M.VK_STRUCTURE_TYPE_INDIRECT_COMMANDS_LAYOUT_CREATE_INFO_NV = 1000277004
M.VK_STRUCTURE_TYPE_GENERATED_COMMANDS_INFO_NV = 1000277005
M.VK_STRUCTURE_TYPE_GENERATED_COMMANDS_MEMORY_REQUIREMENTS_INFO_NV = 1000277006
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEVICE_GENERATED_COMMANDS_FEATURES_NV = 1000277007
M.VK_OBJECT_TYPE_INDIRECT_COMMANDS_LAYOUT_NV = 1000277000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INHERITED_VIEWPORT_SCISSOR_FEATURES_NV = 1000278000
M.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_VIEWPORT_SCISSOR_INFO_NV = 1000278001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TEXEL_BUFFER_ALIGNMENT_FEATURES_EXT = 1000281000
M.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_RENDER_PASS_TRANSFORM_INFO_QCOM = 1000282000
M.VK_STRUCTURE_TYPE_RENDER_PASS_TRANSFORM_BEGIN_INFO_QCOM = 1000282001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_BIAS_CONTROL_FEATURES_EXT = 1000283000
M.VK_STRUCTURE_TYPE_DEPTH_BIAS_INFO_EXT = 1000283001
M.VK_STRUCTURE_TYPE_DEPTH_BIAS_REPRESENTATION_INFO_EXT = 1000283002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEVICE_MEMORY_REPORT_FEATURES_EXT = 1000284000
M.VK_STRUCTURE_TYPE_DEVICE_DEVICE_MEMORY_REPORT_CREATE_INFO_EXT = 1000284001
M.VK_STRUCTURE_TYPE_DEVICE_MEMORY_REPORT_CALLBACK_DATA_EXT = 1000284002
M.VK_STRUCTURE_TYPE_SAMPLER_CUSTOM_BORDER_COLOR_CREATE_INFO_EXT = 1000287000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CUSTOM_BORDER_COLOR_PROPERTIES_EXT = 1000287001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CUSTOM_BORDER_COLOR_FEATURES_EXT = 1000287002
M.VK_BORDER_COLOR_FLOAT_CUSTOM_EXT = 1000287003
M.VK_BORDER_COLOR_INT_CUSTOM_EXT = 1000287004
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TEXTURE_COMPRESSION_ASTC_3D_FEATURES_EXT = 1000288000
M.VK_FORMAT_ASTC_3x3x3_UNORM_BLOCK_EXT = 1000288000
M.VK_FORMAT_ASTC_3x3x3_SRGB_BLOCK_EXT = 1000288001
M.VK_FORMAT_ASTC_3x3x3_SFLOAT_BLOCK_EXT = 1000288002
M.VK_FORMAT_ASTC_4x3x3_UNORM_BLOCK_EXT = 1000288003
M.VK_FORMAT_ASTC_4x3x3_SRGB_BLOCK_EXT = 1000288004
M.VK_FORMAT_ASTC_4x3x3_SFLOAT_BLOCK_EXT = 1000288005
M.VK_FORMAT_ASTC_4x4x3_UNORM_BLOCK_EXT = 1000288006
M.VK_FORMAT_ASTC_4x4x3_SRGB_BLOCK_EXT = 1000288007
M.VK_FORMAT_ASTC_4x4x3_SFLOAT_BLOCK_EXT = 1000288008
M.VK_FORMAT_ASTC_4x4x4_UNORM_BLOCK_EXT = 1000288009
M.VK_FORMAT_ASTC_4x4x4_SRGB_BLOCK_EXT = 1000288010
M.VK_FORMAT_ASTC_4x4x4_SFLOAT_BLOCK_EXT = 1000288011
M.VK_FORMAT_ASTC_5x4x4_UNORM_BLOCK_EXT = 1000288012
M.VK_FORMAT_ASTC_5x4x4_SRGB_BLOCK_EXT = 1000288013
M.VK_FORMAT_ASTC_5x4x4_SFLOAT_BLOCK_EXT = 1000288014
M.VK_FORMAT_ASTC_5x5x4_UNORM_BLOCK_EXT = 1000288015
M.VK_FORMAT_ASTC_5x5x4_SRGB_BLOCK_EXT = 1000288016
M.VK_FORMAT_ASTC_5x5x4_SFLOAT_BLOCK_EXT = 1000288017
M.VK_FORMAT_ASTC_5x5x5_UNORM_BLOCK_EXT = 1000288018
M.VK_FORMAT_ASTC_5x5x5_SRGB_BLOCK_EXT = 1000288019
M.VK_FORMAT_ASTC_5x5x5_SFLOAT_BLOCK_EXT = 1000288020
M.VK_FORMAT_ASTC_6x5x5_UNORM_BLOCK_EXT = 1000288021
M.VK_FORMAT_ASTC_6x5x5_SRGB_BLOCK_EXT = 1000288022
M.VK_FORMAT_ASTC_6x5x5_SFLOAT_BLOCK_EXT = 1000288023
M.VK_FORMAT_ASTC_6x6x5_UNORM_BLOCK_EXT = 1000288024
M.VK_FORMAT_ASTC_6x6x5_SRGB_BLOCK_EXT = 1000288025
M.VK_FORMAT_ASTC_6x6x5_SFLOAT_BLOCK_EXT = 1000288026
M.VK_FORMAT_ASTC_6x6x6_UNORM_BLOCK_EXT = 1000288027
M.VK_FORMAT_ASTC_6x6x6_SRGB_BLOCK_EXT = 1000288028
M.VK_FORMAT_ASTC_6x6x6_SFLOAT_BLOCK_EXT = 1000288029
M.VK_STRUCTURE_TYPE_PIPELINE_LIBRARY_CREATE_INFO_KHR = 1000290000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENT_BARRIER_FEATURES_NV = 1000292000
M.VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_PRESENT_BARRIER_NV = 1000292001
M.VK_STRUCTURE_TYPE_SWAPCHAIN_PRESENT_BARRIER_CREATE_INFO_NV = 1000292002
M.VK_STRUCTURE_TYPE_PRESENT_ID_KHR = 1000294000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENT_ID_FEATURES_KHR = 1000294001
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_INFO_KHR = 1000299000
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_RATE_CONTROL_INFO_KHR = 1000299001
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_RATE_CONTROL_LAYER_INFO_KHR = 1000299002
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_CAPABILITIES_KHR = 1000299003
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_USAGE_INFO_KHR = 1000299004
M.VK_STRUCTURE_TYPE_QUERY_POOL_VIDEO_ENCODE_FEEDBACK_CREATE_INFO_KHR = 1000299005
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VIDEO_ENCODE_QUALITY_LEVEL_INFO_KHR = 1000299006
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_QUALITY_LEVEL_PROPERTIES_KHR = 1000299007
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_QUALITY_LEVEL_INFO_KHR = 1000299008
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_SESSION_PARAMETERS_GET_INFO_KHR = 1000299009
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_SESSION_PARAMETERS_FEEDBACK_INFO_KHR = 1000299010
M.VK_IMAGE_LAYOUT_VIDEO_ENCODE_DST_KHR = 1000299000
M.VK_IMAGE_LAYOUT_VIDEO_ENCODE_SRC_KHR = 1000299001
M.VK_IMAGE_LAYOUT_VIDEO_ENCODE_DPB_KHR = 1000299002
M.VK_QUERY_TYPE_VIDEO_ENCODE_FEEDBACK_KHR = 1000299000
M.VK_QUERY_RESULT_STATUS_INSUFFICIENT_BITSTREAM_BUFFER_RANGE_KHR = -1000299000
M.VK_ERROR_INVALID_VIDEO_STD_PARAMETERS_KHR = -1000299000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DIAGNOSTICS_CONFIG_FEATURES_NV = 1000300000
M.VK_STRUCTURE_TYPE_DEVICE_DIAGNOSTICS_CONFIG_CREATE_INFO_NV = 1000300001
M.VK_STRUCTURE_TYPE_CUDA_MODULE_CREATE_INFO_NV = 1000307000
M.VK_STRUCTURE_TYPE_CUDA_FUNCTION_CREATE_INFO_NV = 1000307001
M.VK_STRUCTURE_TYPE_CUDA_LAUNCH_INFO_NV = 1000307002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CUDA_KERNEL_LAUNCH_FEATURES_NV = 1000307003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CUDA_KERNEL_LAUNCH_PROPERTIES_NV = 1000307004
M.VK_OBJECT_TYPE_CUDA_MODULE_NV = 1000307000
M.VK_OBJECT_TYPE_CUDA_FUNCTION_NV = 1000307001
M.VK_DEBUG_REPORT_OBJECT_TYPE_CUDA_MODULE_NV_EXT = 1000307000
M.VK_DEBUG_REPORT_OBJECT_TYPE_CUDA_FUNCTION_NV_EXT = 1000307001
M.VK_STRUCTURE_TYPE_REFRESH_OBJECT_LIST_KHR = 1000308000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TILE_SHADING_FEATURES_QCOM = 1000309000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TILE_SHADING_PROPERTIES_QCOM = 1000309001
M.VK_STRUCTURE_TYPE_RENDER_PASS_TILE_SHADING_CREATE_INFO_QCOM = 1000309002
M.VK_STRUCTURE_TYPE_PER_TILE_BEGIN_INFO_QCOM = 1000309003
M.VK_STRUCTURE_TYPE_PER_TILE_END_INFO_QCOM = 1000309004
M.VK_STRUCTURE_TYPE_DISPATCH_TILE_INFO_QCOM = 1000309005
M.VK_STRUCTURE_TYPE_QUERY_LOW_LATENCY_SUPPORT_NV = 1000310000
M.VK_STRUCTURE_TYPE_EXPORT_METAL_OBJECT_CREATE_INFO_EXT = 1000311000
M.VK_STRUCTURE_TYPE_EXPORT_METAL_OBJECTS_INFO_EXT = 1000311001
M.VK_STRUCTURE_TYPE_EXPORT_METAL_DEVICE_INFO_EXT = 1000311002
M.VK_STRUCTURE_TYPE_EXPORT_METAL_COMMAND_QUEUE_INFO_EXT = 1000311003
M.VK_STRUCTURE_TYPE_EXPORT_METAL_BUFFER_INFO_EXT = 1000311004
M.VK_STRUCTURE_TYPE_IMPORT_METAL_BUFFER_INFO_EXT = 1000311005
M.VK_STRUCTURE_TYPE_EXPORT_METAL_TEXTURE_INFO_EXT = 1000311006
M.VK_STRUCTURE_TYPE_IMPORT_METAL_TEXTURE_INFO_EXT = 1000311007
M.VK_STRUCTURE_TYPE_EXPORT_METAL_IO_SURFACE_INFO_EXT = 1000311008
M.VK_STRUCTURE_TYPE_IMPORT_METAL_IO_SURFACE_INFO_EXT = 1000311009
M.VK_STRUCTURE_TYPE_EXPORT_METAL_SHARED_EVENT_INFO_EXT = 1000311010
M.VK_STRUCTURE_TYPE_IMPORT_METAL_SHARED_EVENT_INFO_EXT = 1000311011
M.VK_ACCESS_2_NONE_KHR = 0
M.VK_ACCESS_2_INDIRECT_COMMAND_READ_BIT_KHR = 1
M.VK_ACCESS_2_INDEX_READ_BIT_KHR = 2
M.VK_ACCESS_2_VERTEX_ATTRIBUTE_READ_BIT_KHR = 4
M.VK_ACCESS_2_UNIFORM_READ_BIT_KHR = 8
M.VK_ACCESS_2_INPUT_ATTACHMENT_READ_BIT_KHR = 16
M.VK_ACCESS_2_SHADER_READ_BIT_KHR = 32
M.VK_ACCESS_2_SHADER_WRITE_BIT_KHR = 64
M.VK_ACCESS_2_COLOR_ATTACHMENT_READ_BIT_KHR = 128
M.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT_KHR = 256
M.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_READ_BIT_KHR = 512
M.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT_KHR = 1024
M.VK_ACCESS_2_TRANSFER_READ_BIT_KHR = 2048
M.VK_ACCESS_2_TRANSFER_WRITE_BIT_KHR = 4096
M.VK_ACCESS_2_HOST_READ_BIT_KHR = 8192
M.VK_ACCESS_2_HOST_WRITE_BIT_KHR = 16384
M.VK_ACCESS_2_MEMORY_READ_BIT_KHR = 32768
M.VK_ACCESS_2_MEMORY_WRITE_BIT_KHR = 65536
M.VK_ACCESS_2_SHADER_SAMPLED_READ_BIT_KHR = 4294967296
M.VK_ACCESS_2_SHADER_STORAGE_READ_BIT_KHR = 8589934592
M.VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT_KHR = 17179869184
M.VK_PIPELINE_STAGE_2_NONE_KHR = 0
M.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT_KHR = 1
M.VK_PIPELINE_STAGE_2_DRAW_INDIRECT_BIT_KHR = 2
M.VK_PIPELINE_STAGE_2_VERTEX_INPUT_BIT_KHR = 4
M.VK_PIPELINE_STAGE_2_VERTEX_SHADER_BIT_KHR = 8
M.VK_PIPELINE_STAGE_2_TESSELLATION_CONTROL_SHADER_BIT_KHR = 16
M.VK_PIPELINE_STAGE_2_TESSELLATION_EVALUATION_SHADER_BIT_KHR = 32
M.VK_PIPELINE_STAGE_2_GEOMETRY_SHADER_BIT_KHR = 64
M.VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT_KHR = 128
M.VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT_KHR = 256
M.VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT_KHR = 512
M.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT_KHR = 1024
M.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT_KHR = 2048
M.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT_KHR = 4096
M.VK_PIPELINE_STAGE_2_TRANSFER_BIT_KHR = 4096
M.VK_PIPELINE_STAGE_2_BOTTOM_OF_PIPE_BIT_KHR = 8192
M.VK_PIPELINE_STAGE_2_HOST_BIT_KHR = 16384
M.VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT_KHR = 32768
M.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT_KHR = 65536
M.VK_PIPELINE_STAGE_2_COPY_BIT_KHR = 4294967296
M.VK_PIPELINE_STAGE_2_RESOLVE_BIT_KHR = 8589934592
M.VK_PIPELINE_STAGE_2_BLIT_BIT_KHR = 17179869184
M.VK_PIPELINE_STAGE_2_CLEAR_BIT_KHR = 34359738368
M.VK_PIPELINE_STAGE_2_INDEX_INPUT_BIT_KHR = 68719476736
M.VK_PIPELINE_STAGE_2_VERTEX_ATTRIBUTE_INPUT_BIT_KHR = 137438953472
M.VK_PIPELINE_STAGE_2_PRE_RASTERIZATION_SHADERS_BIT_KHR = 274877906944
M.VK_SUBMIT_PROTECTED_BIT_KHR = 1
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_BUFFER_PROPERTIES_EXT = 1000316000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_BUFFER_DENSITY_MAP_PROPERTIES_EXT = 1000316001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_BUFFER_FEATURES_EXT = 1000316002
M.VK_STRUCTURE_TYPE_DESCRIPTOR_ADDRESS_INFO_EXT = 1000316003
M.VK_STRUCTURE_TYPE_DESCRIPTOR_GET_INFO_EXT = 1000316004
M.VK_STRUCTURE_TYPE_BUFFER_CAPTURE_DESCRIPTOR_DATA_INFO_EXT = 1000316005
M.VK_STRUCTURE_TYPE_IMAGE_CAPTURE_DESCRIPTOR_DATA_INFO_EXT = 1000316006
M.VK_STRUCTURE_TYPE_IMAGE_VIEW_CAPTURE_DESCRIPTOR_DATA_INFO_EXT = 1000316007
M.VK_STRUCTURE_TYPE_SAMPLER_CAPTURE_DESCRIPTOR_DATA_INFO_EXT = 1000316008
M.VK_STRUCTURE_TYPE_OPAQUE_CAPTURE_DESCRIPTOR_DATA_CREATE_INFO_EXT = 1000316010
M.VK_STRUCTURE_TYPE_DESCRIPTOR_BUFFER_BINDING_INFO_EXT = 1000316011
M.VK_STRUCTURE_TYPE_DESCRIPTOR_BUFFER_BINDING_PUSH_DESCRIPTOR_BUFFER_HANDLE_EXT = 1000316012
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CAPTURE_DESCRIPTOR_DATA_INFO_EXT = 1000316009
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GRAPHICS_PIPELINE_LIBRARY_FEATURES_EXT = 1000320000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GRAPHICS_PIPELINE_LIBRARY_PROPERTIES_EXT = 1000320001
M.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_LIBRARY_CREATE_INFO_EXT = 1000320002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_EARLY_AND_LATE_FRAGMENT_TESTS_FEATURES_AMD = 1000321000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADER_BARYCENTRIC_FEATURES_KHR = 1000203000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADER_BARYCENTRIC_PROPERTIES_KHR = 1000322000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SUBGROUP_UNIFORM_CONTROL_FLOW_FEATURES_KHR = 1000323000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADING_RATE_ENUMS_PROPERTIES_NV = 1000326000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADING_RATE_ENUMS_FEATURES_NV = 1000326001
M.VK_STRUCTURE_TYPE_PIPELINE_FRAGMENT_SHADING_RATE_ENUM_STATE_CREATE_INFO_NV = 1000326002
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_MOTION_TRIANGLES_DATA_NV = 1000327000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_MOTION_BLUR_FEATURES_NV = 1000327001
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_MOTION_INFO_NV = 1000327002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_FEATURES_EXT = 1000328000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_PROPERTIES_EXT = 1000328001
M.VK_QUERY_TYPE_MESH_PRIMITIVES_GENERATED_EXT = 1000328000
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_MESH_TASKS_NV = 1000328000
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_MESH_TASKS_EXT = 1000328000
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_MESH_TASKS_COUNT_EXT = 1000328001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_YCBCR_2_PLANE_444_FORMATS_FEATURES_EXT = 1000330000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_2_FEATURES_EXT = 1000332000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_2_PROPERTIES_EXT = 1000332001
M.VK_STRUCTURE_TYPE_COPY_COMMAND_TRANSFORM_INFO_QCOM = 1000333000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_WORKGROUP_MEMORY_EXPLICIT_LAYOUT_FEATURES_KHR = 1000336000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_COMPRESSION_CONTROL_FEATURES_EXT = 1000338000
M.VK_STRUCTURE_TYPE_IMAGE_COMPRESSION_CONTROL_EXT = 1000338001
M.VK_STRUCTURE_TYPE_IMAGE_COMPRESSION_PROPERTIES_EXT = 1000338004
M.VK_ERROR_COMPRESSION_EXHAUSTED_EXT = -1000338000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ATTACHMENT_FEEDBACK_LOOP_LAYOUT_FEATURES_EXT = 1000339000
M.VK_IMAGE_LAYOUT_ATTACHMENT_FEEDBACK_LOOP_OPTIMAL_EXT = 1000339000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_4444_FORMATS_FEATURES_EXT = 1000340000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FAULT_FEATURES_EXT = 1000341000
M.VK_STRUCTURE_TYPE_DEVICE_FAULT_COUNTS_EXT = 1000341001
M.VK_STRUCTURE_TYPE_DEVICE_FAULT_INFO_EXT = 1000341002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RGBA10X6_FORMATS_FEATURES_EXT = 1000344000
M.VK_STRUCTURE_TYPE_DIRECTFB_SURFACE_CREATE_INFO_EXT = 1000346000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_INPUT_DYNAMIC_STATE_FEATURES_EXT = 1000352000
M.VK_STRUCTURE_TYPE_VERTEX_INPUT_BINDING_DESCRIPTION_2_EXT = 1000352001
M.VK_STRUCTURE_TYPE_VERTEX_INPUT_ATTRIBUTE_DESCRIPTION_2_EXT = 1000352002
M.VK_DYNAMIC_STATE_VERTEX_INPUT_EXT = 1000352000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DRM_PROPERTIES_EXT = 1000353000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ADDRESS_BINDING_REPORT_FEATURES_EXT = 1000354000
M.VK_STRUCTURE_TYPE_DEVICE_ADDRESS_BINDING_CALLBACK_DATA_EXT = 1000354001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_CLIP_CONTROL_FEATURES_EXT = 1000355000
M.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_DEPTH_CLIP_CONTROL_CREATE_INFO_EXT = 1000355001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRIMITIVE_TOPOLOGY_LIST_RESTART_FEATURES_EXT = 1000356000
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_BIT_KHR = 1
M.VK_FORMAT_FEATURE_2_STORAGE_IMAGE_BIT_KHR = 2
M.VK_FORMAT_FEATURE_2_STORAGE_IMAGE_ATOMIC_BIT_KHR = 4
M.VK_FORMAT_FEATURE_2_UNIFORM_TEXEL_BUFFER_BIT_KHR = 8
M.VK_FORMAT_FEATURE_2_STORAGE_TEXEL_BUFFER_BIT_KHR = 16
M.VK_FORMAT_FEATURE_2_STORAGE_TEXEL_BUFFER_ATOMIC_BIT_KHR = 32
M.VK_FORMAT_FEATURE_2_VERTEX_BUFFER_BIT_KHR = 64
M.VK_FORMAT_FEATURE_2_COLOR_ATTACHMENT_BIT_KHR = 128
M.VK_FORMAT_FEATURE_2_COLOR_ATTACHMENT_BLEND_BIT_KHR = 256
M.VK_FORMAT_FEATURE_2_DEPTH_STENCIL_ATTACHMENT_BIT_KHR = 512
M.VK_FORMAT_FEATURE_2_BLIT_SRC_BIT_KHR = 1024
M.VK_FORMAT_FEATURE_2_BLIT_DST_BIT_KHR = 2048
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_FILTER_LINEAR_BIT_KHR = 4096
M.VK_FORMAT_FEATURE_2_TRANSFER_SRC_BIT_KHR = 16384
M.VK_FORMAT_FEATURE_2_TRANSFER_DST_BIT_KHR = 32768
M.VK_FORMAT_FEATURE_2_MIDPOINT_CHROMA_SAMPLES_BIT_KHR = 131072
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT_KHR = 262144
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT_KHR = 524288
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_BIT_KHR = 1048576
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_BIT_KHR = 2097152
M.VK_FORMAT_FEATURE_2_DISJOINT_BIT_KHR = 4194304
M.VK_FORMAT_FEATURE_2_COSITED_CHROMA_SAMPLES_BIT_KHR = 8388608
M.VK_FORMAT_FEATURE_2_STORAGE_READ_WITHOUT_FORMAT_BIT_KHR = 2147483648
M.VK_FORMAT_FEATURE_2_STORAGE_WRITE_WITHOUT_FORMAT_BIT_KHR = 4294967296
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_DEPTH_COMPARISON_BIT_KHR = 8589934592
M.VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_FILTER_MINMAX_BIT_KHR = 65536
M.VK_STRUCTURE_TYPE_IMPORT_MEMORY_ZIRCON_HANDLE_INFO_FUCHSIA = 1000364000
M.VK_STRUCTURE_TYPE_MEMORY_ZIRCON_HANDLE_PROPERTIES_FUCHSIA = 1000364001
M.VK_STRUCTURE_TYPE_MEMORY_GET_ZIRCON_HANDLE_INFO_FUCHSIA = 1000364002
M.VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_ZIRCON_HANDLE_INFO_FUCHSIA = 1000365000
M.VK_STRUCTURE_TYPE_SEMAPHORE_GET_ZIRCON_HANDLE_INFO_FUCHSIA = 1000365001
M.VK_STRUCTURE_TYPE_BUFFER_COLLECTION_CREATE_INFO_FUCHSIA = 1000366000
M.VK_OBJECT_TYPE_BUFFER_COLLECTION_FUCHSIA = 1000366000
M.VK_STRUCTURE_TYPE_IMPORT_MEMORY_BUFFER_COLLECTION_FUCHSIA = 1000366001
M.VK_STRUCTURE_TYPE_BUFFER_COLLECTION_IMAGE_CREATE_INFO_FUCHSIA = 1000366002
M.VK_STRUCTURE_TYPE_BUFFER_COLLECTION_PROPERTIES_FUCHSIA = 1000366003
M.VK_STRUCTURE_TYPE_BUFFER_CONSTRAINTS_INFO_FUCHSIA = 1000366004
M.VK_STRUCTURE_TYPE_BUFFER_COLLECTION_BUFFER_CREATE_INFO_FUCHSIA = 1000366005
M.VK_STRUCTURE_TYPE_IMAGE_CONSTRAINTS_INFO_FUCHSIA = 1000366006
M.VK_STRUCTURE_TYPE_IMAGE_FORMAT_CONSTRAINTS_INFO_FUCHSIA = 1000366007
M.VK_STRUCTURE_TYPE_SYSMEM_COLOR_SPACE_FUCHSIA = 1000366008
M.VK_STRUCTURE_TYPE_BUFFER_COLLECTION_CONSTRAINTS_INFO_FUCHSIA = 1000366009
M.VK_DEBUG_REPORT_OBJECT_TYPE_BUFFER_COLLECTION_FUCHSIA_EXT = 1000366000
M.VK_STRUCTURE_TYPE_SUBPASS_SHADING_PIPELINE_CREATE_INFO_HUAWEI = 1000369000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBPASS_SHADING_FEATURES_HUAWEI = 1000369001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBPASS_SHADING_PROPERTIES_HUAWEI = 1000369002
M.VK_PIPELINE_BIND_POINT_SUBPASS_SHADING_HUAWEI = 1000369003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INVOCATION_MASK_FEATURES_HUAWEI = 1000370000
M.VK_STRUCTURE_TYPE_MEMORY_GET_REMOTE_ADDRESS_INFO_NV = 1000371000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_MEMORY_RDMA_FEATURES_NV = 1000371001
M.VK_STRUCTURE_TYPE_PIPELINE_PROPERTIES_IDENTIFIER_EXT = 1000372000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_PROPERTIES_FEATURES_EXT = 1000372001
M.VK_STRUCTURE_TYPE_PIPELINE_INFO_EXT = 1000269001
M.VK_STRUCTURE_TYPE_IMPORT_FENCE_SCI_SYNC_INFO_NV = 1000373000
M.VK_STRUCTURE_TYPE_EXPORT_FENCE_SCI_SYNC_INFO_NV = 1000373001
M.VK_STRUCTURE_TYPE_FENCE_GET_SCI_SYNC_INFO_NV = 1000373002
M.VK_STRUCTURE_TYPE_SCI_SYNC_ATTRIBUTES_INFO_NV = 1000373003
M.VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_SCI_SYNC_INFO_NV = 1000373004
M.VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_SCI_SYNC_INFO_NV = 1000373005
M.VK_STRUCTURE_TYPE_SEMAPHORE_GET_SCI_SYNC_INFO_NV = 1000373006
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SCI_SYNC_FEATURES_NV = 1000373007
M.VK_STRUCTURE_TYPE_IMPORT_MEMORY_SCI_BUF_INFO_NV = 1000374000
M.VK_STRUCTURE_TYPE_EXPORT_MEMORY_SCI_BUF_INFO_NV = 1000374001
M.VK_STRUCTURE_TYPE_MEMORY_GET_SCI_BUF_INFO_NV = 1000374002
M.VK_STRUCTURE_TYPE_MEMORY_SCI_BUF_PROPERTIES_NV = 1000374003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_MEMORY_SCI_BUF_FEATURES_NV = 1000374004
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SCI_BUF_FEATURES_NV = 1000374004
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAME_BOUNDARY_FEATURES_EXT = 1000375000
M.VK_STRUCTURE_TYPE_FRAME_BOUNDARY_EXT = 1000375001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTISAMPLED_RENDER_TO_SINGLE_SAMPLED_FEATURES_EXT = 1000376000
M.VK_STRUCTURE_TYPE_SUBPASS_RESOLVE_PERFORMANCE_QUERY_EXT = 1000376001
M.VK_STRUCTURE_TYPE_MULTISAMPLED_RENDER_TO_SINGLE_SAMPLED_INFO_EXT = 1000376002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTENDED_DYNAMIC_STATE_2_FEATURES_EXT = 1000377000
M.VK_DYNAMIC_STATE_PATCH_CONTROL_POINTS_EXT = 1000377000
M.VK_DYNAMIC_STATE_LOGIC_OP_EXT = 1000377003
M.VK_STRUCTURE_TYPE_SCREEN_SURFACE_CREATE_INFO_QNX = 1000378000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COLOR_WRITE_ENABLE_FEATURES_EXT = 1000381000
M.VK_STRUCTURE_TYPE_PIPELINE_COLOR_WRITE_CREATE_INFO_EXT = 1000381001
M.VK_DYNAMIC_STATE_COLOR_WRITE_ENABLE_EXT = 1000381000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRIMITIVES_GENERATED_QUERY_FEATURES_EXT = 1000382000
M.VK_QUERY_TYPE_PRIMITIVES_GENERATED_EXT = 1000382000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_MAINTENANCE_1_FEATURES_KHR = 1000386000
M.VK_QUERY_TYPE_ACCELERATION_STRUCTURE_SERIALIZATION_BOTTOM_LEVEL_POINTERS_KHR = 1000386000
M.VK_QUERY_TYPE_ACCELERATION_STRUCTURE_SIZE_KHR = 1000386001
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_TRACE_RAYS2_EXT = 1000386004
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_UNTYPED_POINTERS_FEATURES_KHR = 1000387000
M.VK_MAX_GLOBAL_PRIORITY_SIZE_EXT = 16
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VIDEO_ENCODE_RGB_CONVERSION_FEATURES_VALVE = 1000390000
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_RGB_CONVERSION_CAPABILITIES_VALVE = 1000390001
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_PROFILE_RGB_CONVERSION_INFO_VALVE = 1000390002
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_SESSION_RGB_CONVERSION_CREATE_INFO_VALVE = 1000390003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_VIEW_MIN_LOD_FEATURES_EXT = 1000391000
M.VK_STRUCTURE_TYPE_IMAGE_VIEW_MIN_LOD_CREATE_INFO_EXT = 1000391001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTI_DRAW_FEATURES_EXT = 1000392000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTI_DRAW_PROPERTIES_EXT = 1000392001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_2D_VIEW_OF_3D_FEATURES_EXT = 1000393000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_TILE_IMAGE_FEATURES_EXT = 1000395000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_TILE_IMAGE_PROPERTIES_EXT = 1000395001
M.VK_STRUCTURE_TYPE_MICROMAP_BUILD_INFO_EXT = 1000396000
M.VK_STRUCTURE_TYPE_MICROMAP_VERSION_INFO_EXT = 1000396001
M.VK_STRUCTURE_TYPE_COPY_MICROMAP_INFO_EXT = 1000396002
M.VK_STRUCTURE_TYPE_COPY_MICROMAP_TO_MEMORY_INFO_EXT = 1000396003
M.VK_STRUCTURE_TYPE_COPY_MEMORY_TO_MICROMAP_INFO_EXT = 1000396004
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_OPACITY_MICROMAP_FEATURES_EXT = 1000396005
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_OPACITY_MICROMAP_PROPERTIES_EXT = 1000396006
M.VK_STRUCTURE_TYPE_MICROMAP_CREATE_INFO_EXT = 1000396007
M.VK_STRUCTURE_TYPE_MICROMAP_BUILD_SIZES_INFO_EXT = 1000396008
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_TRIANGLES_OPACITY_MICROMAP_EXT = 1000396009
M.VK_QUERY_TYPE_MICROMAP_SERIALIZATION_SIZE_EXT = 1000396000
M.VK_QUERY_TYPE_MICROMAP_COMPACTED_SIZE_EXT = 1000396001
M.VK_OBJECT_TYPE_MICROMAP_EXT = 1000396000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DISPLACEMENT_MICROMAP_FEATURES_NV = 1000397000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DISPLACEMENT_MICROMAP_PROPERTIES_NV = 1000397001
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_TRIANGLES_DISPLACEMENT_MICROMAP_NV = 1000397002
M.VK_MICROMAP_TYPE_DISPLACEMENT_MICROMAP_NV = 1000397000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CLUSTER_CULLING_SHADER_FEATURES_HUAWEI = 1000404000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CLUSTER_CULLING_SHADER_PROPERTIES_HUAWEI = 1000404001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CLUSTER_CULLING_SHADER_VRS_FEATURES_HUAWEI = 1000404002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BORDER_COLOR_SWIZZLE_FEATURES_EXT = 1000411000
M.VK_STRUCTURE_TYPE_SAMPLER_BORDER_COLOR_COMPONENT_MAPPING_CREATE_INFO_EXT = 1000411001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PAGEABLE_DEVICE_LOCAL_MEMORY_FEATURES_EXT = 1000412000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_CORE_PROPERTIES_ARM = 1000415000
M.VK_STRUCTURE_TYPE_DEVICE_QUEUE_SHADER_CORE_CONTROL_CREATE_INFO_ARM = 1000417000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SCHEDULING_CONTROLS_FEATURES_ARM = 1000417001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SCHEDULING_CONTROLS_PROPERTIES_ARM = 1000417002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_SLICED_VIEW_OF_3D_FEATURES_EXT = 1000418000
M.VK_STRUCTURE_TYPE_IMAGE_VIEW_SLICED_CREATE_INFO_EXT = 1000418001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_SET_HOST_MAPPING_FEATURES_VALVE = 1000420000
M.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_BINDING_REFERENCE_VALVE = 1000420001
M.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_HOST_MAPPING_INFO_VALVE = 1000420002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_NON_SEAMLESS_CUBE_MAP_FEATURES_EXT = 1000422000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RENDER_PASS_STRIPED_FEATURES_ARM = 1000424000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RENDER_PASS_STRIPED_PROPERTIES_ARM = 1000424001
M.VK_STRUCTURE_TYPE_RENDER_PASS_STRIPE_BEGIN_INFO_ARM = 1000424002
M.VK_STRUCTURE_TYPE_RENDER_PASS_STRIPE_INFO_ARM = 1000424003
M.VK_STRUCTURE_TYPE_RENDER_PASS_STRIPE_SUBMIT_INFO_ARM = 1000424004
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COPY_MEMORY_INDIRECT_FEATURES_NV = 1000426000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEVICE_GENERATED_COMMANDS_COMPUTE_FEATURES_NV = 1000428000
M.VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_INDIRECT_BUFFER_INFO_NV = 1000428001
M.VK_STRUCTURE_TYPE_PIPELINE_INDIRECT_DEVICE_ADDRESS_INFO_NV = 1000428002
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_PIPELINE_NV = 1000428003
M.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DISPATCH_NV = 1000428004
M.VK_GEOMETRY_TYPE_SPHERES_NV = 1000429004
M.VK_GEOMETRY_TYPE_LINEAR_SWEPT_SPHERES_NV = 1000429005
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_LINEAR_SWEPT_SPHERES_FEATURES_NV = 1000429008
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_LINEAR_SWEPT_SPHERES_DATA_NV = 1000429009
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_SPHERES_DATA_NV = 1000429010
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_LINEAR_COLOR_ATTACHMENT_FEATURES_NV = 1000430000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_MAXIMAL_RECONVERGENCE_FEATURES_KHR = 1000434000
M.VK_STRUCTURE_TYPE_APPLICATION_PARAMETERS_EXT = 1000435000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_COMPRESSION_CONTROL_SWAPCHAIN_FEATURES_EXT = 1000437000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_PROCESSING_FEATURES_QCOM = 1000440000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_PROCESSING_PROPERTIES_QCOM = 1000440001
M.VK_STRUCTURE_TYPE_IMAGE_VIEW_SAMPLE_WEIGHT_CREATE_INFO_QCOM = 1000440002
M.VK_DESCRIPTOR_TYPE_SAMPLE_WEIGHT_IMAGE_QCOM = 1000440000
M.VK_DESCRIPTOR_TYPE_BLOCK_MATCH_IMAGE_QCOM = 1000440001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_NESTED_COMMAND_BUFFER_FEATURES_EXT = 1000451000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_NESTED_COMMAND_BUFFER_PROPERTIES_EXT = 1000451001
M.VK_STRUCTURE_TYPE_NATIVE_BUFFER_USAGE_OHOS = 1000452000
M.VK_STRUCTURE_TYPE_NATIVE_BUFFER_PROPERTIES_OHOS = 1000452001
M.VK_STRUCTURE_TYPE_NATIVE_BUFFER_FORMAT_PROPERTIES_OHOS = 1000452002
M.VK_STRUCTURE_TYPE_IMPORT_NATIVE_BUFFER_INFO_OHOS = 1000452003
M.VK_STRUCTURE_TYPE_MEMORY_GET_NATIVE_BUFFER_INFO_OHOS = 1000452004
M.VK_STRUCTURE_TYPE_EXTERNAL_FORMAT_OHOS = 1000452005
M.VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_ACQUIRE_UNMODIFIED_EXT = 1000453000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTENDED_DYNAMIC_STATE_3_FEATURES_EXT = 1000455000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTENDED_DYNAMIC_STATE_3_PROPERTIES_EXT = 1000455001
M.VK_DYNAMIC_STATE_DEPTH_CLAMP_ENABLE_EXT = 1000455003
M.VK_DYNAMIC_STATE_POLYGON_MODE_EXT = 1000455004
M.VK_DYNAMIC_STATE_RASTERIZATION_SAMPLES_EXT = 1000455005
M.VK_DYNAMIC_STATE_SAMPLE_MASK_EXT = 1000455006
M.VK_DYNAMIC_STATE_ALPHA_TO_COVERAGE_ENABLE_EXT = 1000455007
M.VK_DYNAMIC_STATE_ALPHA_TO_ONE_ENABLE_EXT = 1000455008
M.VK_DYNAMIC_STATE_LOGIC_OP_ENABLE_EXT = 1000455009
M.VK_DYNAMIC_STATE_COLOR_BLEND_ENABLE_EXT = 1000455010
M.VK_DYNAMIC_STATE_COLOR_BLEND_EQUATION_EXT = 1000455011
M.VK_DYNAMIC_STATE_COLOR_WRITE_MASK_EXT = 1000455012
M.VK_DYNAMIC_STATE_TESSELLATION_DOMAIN_ORIGIN_EXT = 1000455002
M.VK_DYNAMIC_STATE_RASTERIZATION_STREAM_EXT = 1000455013
M.VK_DYNAMIC_STATE_CONSERVATIVE_RASTERIZATION_MODE_EXT = 1000455014
M.VK_DYNAMIC_STATE_EXTRA_PRIMITIVE_OVERESTIMATION_SIZE_EXT = 1000455015
M.VK_DYNAMIC_STATE_DEPTH_CLIP_ENABLE_EXT = 1000455016
M.VK_DYNAMIC_STATE_SAMPLE_LOCATIONS_ENABLE_EXT = 1000455017
M.VK_DYNAMIC_STATE_COLOR_BLEND_ADVANCED_EXT = 1000455018
M.VK_DYNAMIC_STATE_PROVOKING_VERTEX_MODE_EXT = 1000455019
M.VK_DYNAMIC_STATE_LINE_RASTERIZATION_MODE_EXT = 1000455020
M.VK_DYNAMIC_STATE_LINE_STIPPLE_ENABLE_EXT = 1000455021
M.VK_DYNAMIC_STATE_DEPTH_CLIP_NEGATIVE_ONE_TO_ONE_EXT = 1000455022
M.VK_DYNAMIC_STATE_VIEWPORT_W_SCALING_ENABLE_NV = 1000455023
M.VK_DYNAMIC_STATE_VIEWPORT_SWIZZLE_NV = 1000455024
M.VK_DYNAMIC_STATE_COVERAGE_TO_COLOR_ENABLE_NV = 1000455025
M.VK_DYNAMIC_STATE_COVERAGE_TO_COLOR_LOCATION_NV = 1000455026
M.VK_DYNAMIC_STATE_COVERAGE_MODULATION_MODE_NV = 1000455027
M.VK_DYNAMIC_STATE_COVERAGE_MODULATION_TABLE_ENABLE_NV = 1000455028
M.VK_DYNAMIC_STATE_COVERAGE_MODULATION_TABLE_NV = 1000455029
M.VK_DYNAMIC_STATE_SHADING_RATE_IMAGE_ENABLE_NV = 1000455030
M.VK_DYNAMIC_STATE_REPRESENTATIVE_FRAGMENT_TEST_ENABLE_NV = 1000455031
M.VK_DYNAMIC_STATE_COVERAGE_REDUCTION_MODE_NV = 1000455032
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBPASS_MERGE_FEEDBACK_FEATURES_EXT = 1000458000
M.VK_STRUCTURE_TYPE_RENDER_PASS_CREATION_CONTROL_EXT = 1000458001
M.VK_STRUCTURE_TYPE_RENDER_PASS_CREATION_FEEDBACK_CREATE_INFO_EXT = 1000458002
M.VK_STRUCTURE_TYPE_RENDER_PASS_SUBPASS_FEEDBACK_CREATE_INFO_EXT = 1000458003
M.VK_STRUCTURE_TYPE_DIRECT_DRIVER_LOADING_INFO_LUNARG = 1000459000
M.VK_STRUCTURE_TYPE_DIRECT_DRIVER_LOADING_LIST_LUNARG = 1000459001
M.VK_STRUCTURE_TYPE_TENSOR_CREATE_INFO_ARM = 1000460000
M.VK_STRUCTURE_TYPE_TENSOR_VIEW_CREATE_INFO_ARM = 1000460001
M.VK_STRUCTURE_TYPE_BIND_TENSOR_MEMORY_INFO_ARM = 1000460002
M.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_TENSOR_ARM = 1000460003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TENSOR_PROPERTIES_ARM = 1000460004
M.VK_STRUCTURE_TYPE_TENSOR_FORMAT_PROPERTIES_ARM = 1000460005
M.VK_STRUCTURE_TYPE_TENSOR_DESCRIPTION_ARM = 1000460006
M.VK_STRUCTURE_TYPE_TENSOR_MEMORY_REQUIREMENTS_INFO_ARM = 1000460007
M.VK_STRUCTURE_TYPE_TENSOR_MEMORY_BARRIER_ARM = 1000460008
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TENSOR_FEATURES_ARM = 1000460009
M.VK_STRUCTURE_TYPE_DEVICE_TENSOR_MEMORY_REQUIREMENTS_ARM = 1000460010
M.VK_STRUCTURE_TYPE_COPY_TENSOR_INFO_ARM = 1000460011
M.VK_STRUCTURE_TYPE_TENSOR_COPY_ARM = 1000460012
M.VK_STRUCTURE_TYPE_TENSOR_DEPENDENCY_INFO_ARM = 1000460013
M.VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO_TENSOR_ARM = 1000460014
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_TENSOR_INFO_ARM = 1000460015
M.VK_STRUCTURE_TYPE_EXTERNAL_TENSOR_PROPERTIES_ARM = 1000460016
M.VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_TENSOR_CREATE_INFO_ARM = 1000460017
M.VK_OBJECT_TYPE_TENSOR_ARM = 1000460000
M.VK_OBJECT_TYPE_TENSOR_VIEW_ARM = 1000460001
M.VK_DESCRIPTOR_TYPE_TENSOR_ARM = 1000460000
M.VK_IMAGE_LAYOUT_TENSOR_ALIASING_ARM = 1000460000
M.VK_FORMAT_R8_BOOL_ARM = 1000460000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_BUFFER_TENSOR_FEATURES_ARM = 1000460018
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_BUFFER_TENSOR_PROPERTIES_ARM = 1000460019
M.VK_STRUCTURE_TYPE_DESCRIPTOR_GET_TENSOR_INFO_ARM = 1000460020
M.VK_STRUCTURE_TYPE_TENSOR_CAPTURE_DESCRIPTOR_DATA_INFO_ARM = 1000460021
M.VK_STRUCTURE_TYPE_TENSOR_VIEW_CAPTURE_DESCRIPTOR_DATA_INFO_ARM = 1000460022
M.VK_STRUCTURE_TYPE_FRAME_BOUNDARY_TENSORS_ARM = 1000460023
M.VK_FORMAT_R16_SFLOAT_FPENCODING_BFLOAT16_ARM = 1000460001
M.VK_FORMAT_R8_SFLOAT_FPENCODING_FLOAT8E4M3_ARM = 1000460002
M.VK_FORMAT_R8_SFLOAT_FPENCODING_FLOAT8E5M2_ARM = 1000460003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_MODULE_IDENTIFIER_FEATURES_EXT = 1000462000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_MODULE_IDENTIFIER_PROPERTIES_EXT = 1000462001
M.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_MODULE_IDENTIFIER_CREATE_INFO_EXT = 1000462002
M.VK_STRUCTURE_TYPE_SHADER_MODULE_IDENTIFIER_EXT = 1000462003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RASTERIZATION_ORDER_ATTACHMENT_ACCESS_FEATURES_EXT = 1000342000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_OPTICAL_FLOW_FEATURES_NV = 1000464000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_OPTICAL_FLOW_PROPERTIES_NV = 1000464001
M.VK_STRUCTURE_TYPE_OPTICAL_FLOW_IMAGE_FORMAT_INFO_NV = 1000464002
M.VK_STRUCTURE_TYPE_OPTICAL_FLOW_IMAGE_FORMAT_PROPERTIES_NV = 1000464003
M.VK_STRUCTURE_TYPE_OPTICAL_FLOW_SESSION_CREATE_INFO_NV = 1000464004
M.VK_STRUCTURE_TYPE_OPTICAL_FLOW_EXECUTE_INFO_NV = 1000464005
M.VK_STRUCTURE_TYPE_OPTICAL_FLOW_SESSION_CREATE_PRIVATE_DATA_INFO_NV = 1000464010
M.VK_FORMAT_R16G16_SFIXED5_NV = 1000464000
M.VK_FORMAT_R16G16_S10_5_NV = 1000464000
M.VK_OBJECT_TYPE_OPTICAL_FLOW_SESSION_NV = 1000464000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_LEGACY_DITHERING_FEATURES_EXT = 1000465000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_FORMAT_RESOLVE_FEATURES_ANDROID = 1000468000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_FORMAT_RESOLVE_PROPERTIES_ANDROID = 1000468001
M.VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_FORMAT_RESOLVE_PROPERTIES_ANDROID = 1000468002
M.VK_PIPELINE_CREATE_2_DISABLE_OPTIMIZATION_BIT_KHR = 1
M.VK_PIPELINE_CREATE_2_ALLOW_DERIVATIVES_BIT_KHR = 2
M.VK_PIPELINE_CREATE_2_DERIVATIVE_BIT_KHR = 4
M.VK_PIPELINE_CREATE_2_VIEW_INDEX_FROM_DEVICE_INDEX_BIT_KHR = 8
M.VK_PIPELINE_CREATE_2_DISPATCH_BASE_BIT_KHR = 16
M.VK_BUFFER_USAGE_2_TRANSFER_SRC_BIT_KHR = 1
M.VK_BUFFER_USAGE_2_TRANSFER_DST_BIT_KHR = 2
M.VK_BUFFER_USAGE_2_UNIFORM_TEXEL_BUFFER_BIT_KHR = 4
M.VK_BUFFER_USAGE_2_STORAGE_TEXEL_BUFFER_BIT_KHR = 8
M.VK_BUFFER_USAGE_2_UNIFORM_BUFFER_BIT_KHR = 16
M.VK_BUFFER_USAGE_2_STORAGE_BUFFER_BIT_KHR = 32
M.VK_BUFFER_USAGE_2_INDEX_BUFFER_BIT_KHR = 64
M.VK_BUFFER_USAGE_2_VERTEX_BUFFER_BIT_KHR = 128
M.VK_BUFFER_USAGE_2_INDIRECT_BUFFER_BIT_KHR = 256
M.VK_PIPELINE_CREATE_2_FAIL_ON_PIPELINE_COMPILE_REQUIRED_BIT_KHR = 256
M.VK_PIPELINE_CREATE_2_EARLY_RETURN_ON_FAILURE_BIT_KHR = 512
M.VK_PIPELINE_CREATE_2_NO_PROTECTED_ACCESS_BIT_EXT = 134217728
M.VK_PIPELINE_CREATE_2_PROTECTED_ACCESS_ONLY_BIT_EXT = 1073741824
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ANTI_LAG_FEATURES_AMD = 1000476000
M.VK_STRUCTURE_TYPE_ANTI_LAG_DATA_AMD = 1000476001
M.VK_STRUCTURE_TYPE_ANTI_LAG_PRESENTATION_INFO_AMD = 1000476002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DENSE_GEOMETRY_FORMAT_FEATURES_AMDX = 1000478000
M.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_DENSE_GEOMETRY_FORMAT_TRIANGLES_DATA_AMDX = 1000478001
M.VK_GEOMETRY_TYPE_DENSE_GEOMETRY_FORMAT_TRIANGLES_AMDX = 1000478000
M.VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_PRESENT_ID_2_KHR = 1000479000
M.VK_STRUCTURE_TYPE_PRESENT_ID_2_KHR = 1000479001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENT_ID_2_FEATURES_KHR = 1000479002
M.VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_PRESENT_WAIT_2_KHR = 1000480000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENT_WAIT_2_FEATURES_KHR = 1000480001
M.VK_STRUCTURE_TYPE_PRESENT_WAIT_2_INFO_KHR = 1000480002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_POSITION_FETCH_FEATURES_KHR = 1000481000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_OBJECT_FEATURES_EXT = 1000482000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_OBJECT_PROPERTIES_EXT = 1000482001
M.VK_STRUCTURE_TYPE_SHADER_CREATE_INFO_EXT = 1000482002
M.VK_OBJECT_TYPE_SHADER_EXT = 1000482000
M.VK_INCOMPATIBLE_SHADER_BINARY_EXT = 1000482000
M.VK_ERROR_INCOMPATIBLE_SHADER_BINARY_EXT = 1000482000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_BINARY_FEATURES_KHR = 1000483000
M.VK_STRUCTURE_TYPE_PIPELINE_BINARY_CREATE_INFO_KHR = 1000483001
M.VK_STRUCTURE_TYPE_PIPELINE_BINARY_INFO_KHR = 1000483002
M.VK_STRUCTURE_TYPE_PIPELINE_BINARY_KEY_KHR = 1000483003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_BINARY_PROPERTIES_KHR = 1000483004
M.VK_STRUCTURE_TYPE_RELEASE_CAPTURED_PIPELINE_DATA_INFO_KHR = 1000483005
M.VK_STRUCTURE_TYPE_PIPELINE_BINARY_DATA_INFO_KHR = 1000483006
M.VK_STRUCTURE_TYPE_PIPELINE_CREATE_INFO_KHR = 1000483007
M.VK_STRUCTURE_TYPE_DEVICE_PIPELINE_BINARY_INTERNAL_CACHE_CONTROL_KHR = 1000483008
M.VK_STRUCTURE_TYPE_PIPELINE_BINARY_HANDLES_INFO_KHR = 1000483009
M.VK_OBJECT_TYPE_PIPELINE_BINARY_KHR = 1000483000
M.VK_PIPELINE_BINARY_MISSING_KHR = 1000483000
M.VK_ERROR_NOT_ENOUGH_SPACE_KHR = -1000483000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TILE_PROPERTIES_FEATURES_QCOM = 1000484000
M.VK_STRUCTURE_TYPE_TILE_PROPERTIES_QCOM = 1000484001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_AMIGO_PROFILING_FEATURES_SEC = 1000485000
M.VK_STRUCTURE_TYPE_AMIGO_PROFILING_SUBMIT_INFO_SEC = 1000485001
M.VK_STRUCTURE_TYPE_SURFACE_PRESENT_MODE_KHR = 1000274000
M.VK_STRUCTURE_TYPE_SURFACE_PRESENT_SCALING_CAPABILITIES_KHR = 1000274001
M.VK_STRUCTURE_TYPE_SURFACE_PRESENT_MODE_COMPATIBILITY_KHR = 1000274002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SWAPCHAIN_MAINTENANCE_1_FEATURES_KHR = 1000275000
M.VK_STRUCTURE_TYPE_SWAPCHAIN_PRESENT_FENCE_INFO_KHR = 1000275001
M.VK_STRUCTURE_TYPE_SWAPCHAIN_PRESENT_MODES_CREATE_INFO_KHR = 1000275002
M.VK_STRUCTURE_TYPE_SWAPCHAIN_PRESENT_MODE_INFO_KHR = 1000275003
M.VK_STRUCTURE_TYPE_SWAPCHAIN_PRESENT_SCALING_CREATE_INFO_KHR = 1000275004
M.VK_STRUCTURE_TYPE_RELEASE_SWAPCHAIN_IMAGES_INFO_KHR = 1000275005
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PER_VIEW_VIEWPORTS_FEATURES_QCOM = 1000488000
M.VK_OBJECT_TYPE_SEMAPHORE_SCI_SYNC_POOL_NV = 1000489000
M.VK_STRUCTURE_TYPE_SEMAPHORE_SCI_SYNC_POOL_CREATE_INFO_NV = 1000489000
M.VK_STRUCTURE_TYPE_SEMAPHORE_SCI_SYNC_CREATE_INFO_NV = 1000489001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SCI_SYNC_2_FEATURES_NV = 1000489002
M.VK_STRUCTURE_TYPE_DEVICE_SEMAPHORE_SCI_SYNC_POOL_RESERVATION_CREATE_INFO_NV = 1000489003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_INVOCATION_REORDER_FEATURES_NV = 1000490000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_INVOCATION_REORDER_PROPERTIES_NV = 1000490001
M.VK_RAY_TRACING_INVOCATION_REORDER_MODE_NONE_NV = 0
M.VK_RAY_TRACING_INVOCATION_REORDER_MODE_REORDER_NV = 1
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_VECTOR_FEATURES_NV = 1000491000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_VECTOR_PROPERTIES_NV = 1000491001
M.VK_STRUCTURE_TYPE_COOPERATIVE_VECTOR_PROPERTIES_NV = 1000491002
M.VK_STRUCTURE_TYPE_CONVERT_COOPERATIVE_VECTOR_MATRIX_INFO_NV = 1000491004
M.VK_COMPONENT_TYPE_SINT8_PACKED_NV = 1000491000
M.VK_COMPONENT_TYPE_UINT8_PACKED_NV = 1000491001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTENDED_SPARSE_ADDRESS_SPACE_FEATURES_NV = 1000492000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTENDED_SPARSE_ADDRESS_SPACE_PROPERTIES_NV = 1000492001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MUTABLE_DESCRIPTOR_TYPE_FEATURES_EXT = 1000351000
M.VK_STRUCTURE_TYPE_MUTABLE_DESCRIPTOR_TYPE_CREATE_INFO_EXT = 1000351002
M.VK_DESCRIPTOR_TYPE_MUTABLE_EXT = 1000351000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_LEGACY_VERTEX_ATTRIBUTES_FEATURES_EXT = 1000495000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_LEGACY_VERTEX_ATTRIBUTES_PROPERTIES_EXT = 1000495001
M.VK_STRUCTURE_TYPE_LAYER_SETTINGS_CREATE_INFO_EXT = 1000496000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_CORE_BUILTINS_FEATURES_ARM = 1000497000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_CORE_BUILTINS_PROPERTIES_ARM = 1000497001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_LIBRARY_GROUP_HANDLES_FEATURES_EXT = 1000498000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_UNUSED_ATTACHMENTS_FEATURES_EXT = 1000499000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INTERNALLY_SYNCHRONIZED_QUEUES_FEATURES_KHR = 1000504000
M.VK_STRUCTURE_TYPE_LATENCY_SLEEP_MODE_INFO_NV = 1000505000
M.VK_STRUCTURE_TYPE_LATENCY_SLEEP_INFO_NV = 1000505001
M.VK_STRUCTURE_TYPE_SET_LATENCY_MARKER_INFO_NV = 1000505002
M.VK_STRUCTURE_TYPE_GET_LATENCY_MARKER_INFO_NV = 1000505003
M.VK_STRUCTURE_TYPE_LATENCY_TIMINGS_FRAME_REPORT_NV = 1000505004
M.VK_STRUCTURE_TYPE_LATENCY_SUBMISSION_PRESENT_ID_NV = 1000505005
M.VK_STRUCTURE_TYPE_OUT_OF_BAND_QUEUE_TYPE_INFO_NV = 1000505006
M.VK_STRUCTURE_TYPE_SWAPCHAIN_LATENCY_CREATE_INFO_NV = 1000505007
M.VK_STRUCTURE_TYPE_LATENCY_SURFACE_CAPABILITIES_NV = 1000505008
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR = 1000506000
M.VK_STRUCTURE_TYPE_COOPERATIVE_MATRIX_PROPERTIES_KHR = 1000506001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_PROPERTIES_KHR = 1000506002
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_CREATE_INFO_ARM = 1000507000
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_SESSION_CREATE_INFO_ARM = 1000507001
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_RESOURCE_INFO_ARM = 1000507002
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_CONSTANT_ARM = 1000507003
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_SESSION_MEMORY_REQUIREMENTS_INFO_ARM = 1000507004
M.VK_STRUCTURE_TYPE_BIND_DATA_GRAPH_PIPELINE_SESSION_MEMORY_INFO_ARM = 1000507005
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DATA_GRAPH_FEATURES_ARM = 1000507006
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_SHADER_MODULE_CREATE_INFO_ARM = 1000507007
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_PROPERTY_QUERY_RESULT_ARM = 1000507008
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_INFO_ARM = 1000507009
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_COMPILER_CONTROL_CREATE_INFO_ARM = 1000507010
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_SESSION_BIND_POINT_REQUIREMENTS_INFO_ARM = 1000507011
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_SESSION_BIND_POINT_REQUIREMENT_ARM = 1000507012
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_IDENTIFIER_CREATE_INFO_ARM = 1000507013
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_DISPATCH_INFO_ARM = 1000507014
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PROCESSING_ENGINE_CREATE_INFO_ARM = 1000507016
M.VK_STRUCTURE_TYPE_QUEUE_FAMILY_DATA_GRAPH_PROCESSING_ENGINE_PROPERTIES_ARM = 1000507017
M.VK_STRUCTURE_TYPE_QUEUE_FAMILY_DATA_GRAPH_PROPERTIES_ARM = 1000507018
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_QUEUE_FAMILY_DATA_GRAPH_PROCESSING_ENGINE_INFO_ARM = 1000507019
M.VK_OBJECT_TYPE_DATA_GRAPH_PIPELINE_SESSION_ARM = 1000507000
M.VK_PIPELINE_BIND_POINT_DATA_GRAPH_ARM = 1000507000
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_CONSTANT_TENSOR_SEMI_STRUCTURED_SPARSITY_INFO_ARM = 1000507015
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PER_VIEW_RENDER_AREAS_FEATURES_QCOM = 1000510000
M.VK_STRUCTURE_TYPE_MULTIVIEW_PER_VIEW_RENDER_AREAS_RENDER_PASS_BEGIN_INFO_QCOM = 1000510001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COMPUTE_SHADER_DERIVATIVES_FEATURES_KHR = 1000201000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COMPUTE_SHADER_DERIVATIVES_PROPERTIES_KHR = 1000511000
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_AV1_CAPABILITIES_KHR = 1000512000
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_AV1_PICTURE_INFO_KHR = 1000512001
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_AV1_PROFILE_INFO_KHR = 1000512003
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_AV1_SESSION_PARAMETERS_CREATE_INFO_KHR = 1000512004
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_AV1_DPB_SLOT_INFO_KHR = 1000512005
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_AV1_CAPABILITIES_KHR = 1000513000
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_AV1_SESSION_PARAMETERS_CREATE_INFO_KHR = 1000513001
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_AV1_PICTURE_INFO_KHR = 1000513002
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_AV1_DPB_SLOT_INFO_KHR = 1000513003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VIDEO_ENCODE_AV1_FEATURES_KHR = 1000513004
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_AV1_PROFILE_INFO_KHR = 1000513005
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_AV1_RATE_CONTROL_INFO_KHR = 1000513006
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_AV1_RATE_CONTROL_LAYER_INFO_KHR = 1000513007
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_AV1_QUALITY_LEVEL_PROPERTIES_KHR = 1000513008
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_AV1_SESSION_CREATE_INFO_KHR = 1000513009
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_AV1_GOP_REMAINING_FRAME_INFO_KHR = 1000513010
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VIDEO_DECODE_VP9_FEATURES_KHR = 1000514000
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_VP9_CAPABILITIES_KHR = 1000514001
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_VP9_PICTURE_INFO_KHR = 1000514002
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_VP9_PROFILE_INFO_KHR = 1000514003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VIDEO_MAINTENANCE_1_FEATURES_KHR = 1000515000
M.VK_STRUCTURE_TYPE_VIDEO_INLINE_QUERY_INFO_KHR = 1000515001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PER_STAGE_DESCRIPTOR_SET_FEATURES_NV = 1000516000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_PROCESSING_2_FEATURES_QCOM = 1000518000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_PROCESSING_2_PROPERTIES_QCOM = 1000518001
M.VK_STRUCTURE_TYPE_SAMPLER_BLOCK_MATCH_WINDOW_CREATE_INFO_QCOM = 1000518002
M.VK_STRUCTURE_TYPE_SAMPLER_CUBIC_WEIGHTS_CREATE_INFO_QCOM = 1000519000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CUBIC_WEIGHTS_FEATURES_QCOM = 1000519001
M.VK_STRUCTURE_TYPE_BLIT_IMAGE_CUBIC_WEIGHTS_INFO_QCOM = 1000519002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_YCBCR_DEGAMMA_FEATURES_QCOM = 1000520000
M.VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_YCBCR_DEGAMMA_CREATE_INFO_QCOM = 1000520001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CUBIC_CLAMP_FEATURES_QCOM = 1000521000
M.VK_SAMPLER_REDUCTION_MODE_WEIGHTED_AVERAGE_RANGECLAMP_QCOM = 1000521000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ATTACHMENT_FEEDBACK_LOOP_DYNAMIC_STATE_FEATURES_EXT = 1000524000
M.VK_DYNAMIC_STATE_ATTACHMENT_FEEDBACK_LOOP_ENABLE_EXT = 1000524000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_UNIFIED_IMAGE_LAYOUTS_FEATURES_KHR = 1000527000
M.VK_STRUCTURE_TYPE_ATTACHMENT_FEEDBACK_LOOP_INFO_EXT = 1000527001
M.VK_STRUCTURE_TYPE_SCREEN_BUFFER_PROPERTIES_QNX = 1000529000
M.VK_STRUCTURE_TYPE_SCREEN_BUFFER_FORMAT_PROPERTIES_QNX = 1000529001
M.VK_STRUCTURE_TYPE_IMPORT_SCREEN_BUFFER_INFO_QNX = 1000529002
M.VK_STRUCTURE_TYPE_EXTERNAL_FORMAT_QNX = 1000529003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_MEMORY_SCREEN_BUFFER_FEATURES_QNX = 1000529004
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_LAYERED_DRIVER_PROPERTIES_MSFT = 1000530000
M.VK_LINE_RASTERIZATION_MODE_DEFAULT_KHR = 0
M.VK_LINE_RASTERIZATION_MODE_RECTANGULAR_KHR = 1
M.VK_LINE_RASTERIZATION_MODE_BRESENHAM_KHR = 2
M.VK_LINE_RASTERIZATION_MODE_RECTANGULAR_SMOOTH_KHR = 3
M.VK_STRUCTURE_TYPE_CALIBRATED_TIMESTAMP_INFO_KHR = 1000184000
M.VK_STRUCTURE_TYPE_SET_DESCRIPTOR_BUFFER_OFFSETS_INFO_EXT = 1000545007
M.VK_STRUCTURE_TYPE_BIND_DESCRIPTOR_BUFFER_EMBEDDED_SAMPLERS_INFO_EXT = 1000545008
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_POOL_OVERALLOCATION_FEATURES_NV = 1000546000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TILE_MEMORY_HEAP_FEATURES_QCOM = 1000547000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TILE_MEMORY_HEAP_PROPERTIES_QCOM = 1000547001
M.VK_STRUCTURE_TYPE_TILE_MEMORY_REQUIREMENTS_QCOM = 1000547002
M.VK_STRUCTURE_TYPE_TILE_MEMORY_BIND_INFO_QCOM = 1000547003
M.VK_STRUCTURE_TYPE_TILE_MEMORY_SIZE_INFO_QCOM = 1000547004
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COPY_MEMORY_INDIRECT_FEATURES_KHR = 1000549000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COPY_MEMORY_INDIRECT_PROPERTIES_KHR = 1000426001
M.VK_STRUCTURE_TYPE_COPY_MEMORY_INDIRECT_INFO_KHR = 1000549002
M.VK_STRUCTURE_TYPE_COPY_MEMORY_TO_IMAGE_INDIRECT_INFO_KHR = 1000549003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_DECOMPRESSION_FEATURES_EXT = 1000427000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_DECOMPRESSION_PROPERTIES_EXT = 1000427001
M.VK_STRUCTURE_TYPE_DECOMPRESS_MEMORY_INFO_EXT = 1000550002
M.VK_STRUCTURE_TYPE_DISPLAY_SURFACE_STEREO_CREATE_INFO_NV = 1000551000
M.VK_STRUCTURE_TYPE_DISPLAY_MODE_STEREO_PROPERTIES_NV = 1000551001
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_INTRA_REFRESH_CAPABILITIES_KHR = 1000552000
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_SESSION_INTRA_REFRESH_CREATE_INFO_KHR = 1000552001
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_INTRA_REFRESH_INFO_KHR = 1000552002
M.VK_STRUCTURE_TYPE_VIDEO_REFERENCE_INTRA_REFRESH_INFO_KHR = 1000552003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VIDEO_ENCODE_INTRA_REFRESH_FEATURES_KHR = 1000552004
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_QUANTIZATION_MAP_CAPABILITIES_KHR = 1000553000
M.VK_STRUCTURE_TYPE_VIDEO_FORMAT_QUANTIZATION_MAP_PROPERTIES_KHR = 1000553001
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_QUANTIZATION_MAP_INFO_KHR = 1000553002
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_QUANTIZATION_MAP_SESSION_PARAMETERS_CREATE_INFO_KHR = 1000553005
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VIDEO_ENCODE_QUANTIZATION_MAP_FEATURES_KHR = 1000553009
M.VK_IMAGE_LAYOUT_VIDEO_ENCODE_QUANTIZATION_MAP_KHR = 1000553000
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_QUANTIZATION_MAP_CAPABILITIES_KHR = 1000553003
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_H265_QUANTIZATION_MAP_CAPABILITIES_KHR = 1000553004
M.VK_STRUCTURE_TYPE_VIDEO_FORMAT_H265_QUANTIZATION_MAP_PROPERTIES_KHR = 1000553006
M.VK_STRUCTURE_TYPE_VIDEO_ENCODE_AV1_QUANTIZATION_MAP_CAPABILITIES_KHR = 1000553007
M.VK_STRUCTURE_TYPE_VIDEO_FORMAT_AV1_QUANTIZATION_MAP_PROPERTIES_KHR = 1000553008
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAW_ACCESS_CHAINS_FEATURES_NV = 1000555000
M.VK_STRUCTURE_TYPE_EXTERNAL_COMPUTE_QUEUE_DEVICE_CREATE_INFO_NV = 1000556000
M.VK_STRUCTURE_TYPE_EXTERNAL_COMPUTE_QUEUE_CREATE_INFO_NV = 1000556001
M.VK_STRUCTURE_TYPE_EXTERNAL_COMPUTE_QUEUE_DATA_PARAMS_NV = 1000556002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_COMPUTE_QUEUE_PROPERTIES_NV = 1000556003
M.VK_OBJECT_TYPE_EXTERNAL_COMPUTE_QUEUE_NV = 1000556000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_RELAXED_EXTENDED_INSTRUCTION_FEATURES_KHR = 1000558000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COMMAND_BUFFER_INHERITANCE_FEATURES_NV = 1000559000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_7_FEATURES_KHR = 1000562000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_7_PROPERTIES_KHR = 1000562001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_LAYERED_API_PROPERTIES_LIST_KHR = 1000562002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_LAYERED_API_PROPERTIES_KHR = 1000562003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_LAYERED_API_VULKAN_PROPERTIES_KHR = 1000562004
M.VK_SUBPASS_CONTENTS_INLINE_AND_SECONDARY_COMMAND_BUFFERS_KHR = 1000451000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ATOMIC_FLOAT16_VECTOR_FEATURES_NV = 1000563000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_REPLICATED_COMPOSITES_FEATURES_EXT = 1000564000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_FLOAT8_FEATURES_EXT = 1000567000
M.VK_COMPONENT_TYPE_FLOAT8_E4M3_EXT = 1000491002
M.VK_COMPONENT_TYPE_FLOAT8_E5M2_EXT = 1000491003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_VALIDATION_FEATURES_NV = 1000568000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CLUSTER_ACCELERATION_STRUCTURE_FEATURES_NV = 1000569000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CLUSTER_ACCELERATION_STRUCTURE_PROPERTIES_NV = 1000569001
M.VK_STRUCTURE_TYPE_CLUSTER_ACCELERATION_STRUCTURE_CLUSTERS_BOTTOM_LEVEL_INPUT_NV = 1000569002
M.VK_STRUCTURE_TYPE_CLUSTER_ACCELERATION_STRUCTURE_TRIANGLE_CLUSTER_INPUT_NV = 1000569003
M.VK_STRUCTURE_TYPE_CLUSTER_ACCELERATION_STRUCTURE_MOVE_OBJECTS_INPUT_NV = 1000569004
M.VK_STRUCTURE_TYPE_CLUSTER_ACCELERATION_STRUCTURE_INPUT_INFO_NV = 1000569005
M.VK_STRUCTURE_TYPE_CLUSTER_ACCELERATION_STRUCTURE_COMMANDS_INFO_NV = 1000569006
M.VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CLUSTER_ACCELERATION_STRUCTURE_CREATE_INFO_NV = 1000569007
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PARTITIONED_ACCELERATION_STRUCTURE_FEATURES_NV = 1000570000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PARTITIONED_ACCELERATION_STRUCTURE_PROPERTIES_NV = 1000570001
M.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_PARTITIONED_ACCELERATION_STRUCTURE_NV = 1000570002
M.VK_STRUCTURE_TYPE_PARTITIONED_ACCELERATION_STRUCTURE_INSTANCES_INPUT_NV = 1000570003
M.VK_STRUCTURE_TYPE_BUILD_PARTITIONED_ACCELERATION_STRUCTURE_INFO_NV = 1000570004
M.VK_STRUCTURE_TYPE_PARTITIONED_ACCELERATION_STRUCTURE_FLAGS_NV = 1000570005
M.VK_DESCRIPTOR_TYPE_PARTITIONED_ACCELERATION_STRUCTURE_NV = 1000570000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEVICE_GENERATED_COMMANDS_FEATURES_EXT = 1000572000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEVICE_GENERATED_COMMANDS_PROPERTIES_EXT = 1000572001
M.VK_STRUCTURE_TYPE_GENERATED_COMMANDS_MEMORY_REQUIREMENTS_INFO_EXT = 1000572002
M.VK_STRUCTURE_TYPE_INDIRECT_EXECUTION_SET_CREATE_INFO_EXT = 1000572003
M.VK_STRUCTURE_TYPE_GENERATED_COMMANDS_INFO_EXT = 1000572004
M.VK_STRUCTURE_TYPE_INDIRECT_COMMANDS_LAYOUT_CREATE_INFO_EXT = 1000572006
M.VK_STRUCTURE_TYPE_INDIRECT_COMMANDS_LAYOUT_TOKEN_EXT = 1000572007
M.VK_STRUCTURE_TYPE_WRITE_INDIRECT_EXECUTION_SET_PIPELINE_EXT = 1000572008
M.VK_STRUCTURE_TYPE_WRITE_INDIRECT_EXECUTION_SET_SHADER_EXT = 1000572009
M.VK_STRUCTURE_TYPE_INDIRECT_EXECUTION_SET_PIPELINE_INFO_EXT = 1000572010
M.VK_STRUCTURE_TYPE_INDIRECT_EXECUTION_SET_SHADER_INFO_EXT = 1000572011
M.VK_STRUCTURE_TYPE_INDIRECT_EXECUTION_SET_SHADER_LAYOUT_INFO_EXT = 1000572012
M.VK_STRUCTURE_TYPE_GENERATED_COMMANDS_PIPELINE_INFO_EXT = 1000572013
M.VK_STRUCTURE_TYPE_GENERATED_COMMANDS_SHADER_INFO_EXT = 1000572014
M.VK_OBJECT_TYPE_INDIRECT_COMMANDS_LAYOUT_EXT = 1000572000
M.VK_OBJECT_TYPE_INDIRECT_EXECUTION_SET_EXT = 1000572001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_8_FEATURES_KHR = 1000574000
M.VK_STRUCTURE_TYPE_MEMORY_BARRIER_ACCESS_FLAGS_3_KHR = 1000574002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_ALIGNMENT_CONTROL_FEATURES_MESA = 1000575000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_ALIGNMENT_CONTROL_PROPERTIES_MESA = 1000575001
M.VK_STRUCTURE_TYPE_IMAGE_ALIGNMENT_CONTROL_CREATE_INFO_MESA = 1000575002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_FMA_FEATURES_KHR = 1000579000
M.VK_STRUCTURE_TYPE_PUSH_CONSTANT_BANK_INFO_NV = 1000580000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PUSH_CONSTANT_BANK_FEATURES_NV = 1000580001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PUSH_CONSTANT_BANK_PROPERTIES_NV = 1000580002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_INVOCATION_REORDER_FEATURES_EXT = 1000581000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_INVOCATION_REORDER_PROPERTIES_EXT = 1000581001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_CLAMP_CONTROL_FEATURES_EXT = 1000582000
M.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_DEPTH_CLAMP_CONTROL_CREATE_INFO_EXT = 1000582001
M.VK_DYNAMIC_STATE_DEPTH_CLAMP_RANGE_EXT = 1000582000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_9_FEATURES_KHR = 1000584000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_9_PROPERTIES_KHR = 1000584001
M.VK_STRUCTURE_TYPE_QUEUE_FAMILY_OWNERSHIP_TRANSFER_PROPERTIES_KHR = 1000584002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VIDEO_MAINTENANCE_2_FEATURES_KHR = 1000586000
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H264_INLINE_SESSION_PARAMETERS_INFO_KHR = 1000586001
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_H265_INLINE_SESSION_PARAMETERS_INFO_KHR = 1000586002
M.VK_STRUCTURE_TYPE_VIDEO_DECODE_AV1_INLINE_SESSION_PARAMETERS_INFO_KHR = 1000586003
M.VK_STRUCTURE_TYPE_NATIVE_BUFFER_OHOS = 1000453001
M.VK_STRUCTURE_TYPE_SWAPCHAIN_IMAGE_CREATE_INFO_OHOS = 1000453002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENTATION_PROPERTIES_OHOS = 1000453003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_HDR_VIVID_FEATURES_HUAWEI = 1000590000
M.VK_STRUCTURE_TYPE_HDR_VIVID_DYNAMIC_METADATA_HUAWEI = 1000590001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_2_FEATURES_NV = 1000593000
M.VK_STRUCTURE_TYPE_COOPERATIVE_MATRIX_FLEXIBLE_DIMENSIONS_PROPERTIES_NV = 1000593001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_2_PROPERTIES_NV = 1000593002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_OPACITY_MICROMAP_FEATURES_ARM = 1000596000
M.VK_STRUCTURE_TYPE_IMPORT_MEMORY_METAL_HANDLE_INFO_EXT = 1000602000
M.VK_STRUCTURE_TYPE_MEMORY_METAL_HANDLE_PROPERTIES_EXT = 1000602001
M.VK_STRUCTURE_TYPE_MEMORY_GET_METAL_HANDLE_INFO_EXT = 1000602002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_CLAMP_ZERO_ONE_FEATURES_KHR = 1000421000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PERFORMANCE_COUNTERS_BY_REGION_FEATURES_ARM = 1000605000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PERFORMANCE_COUNTERS_BY_REGION_PROPERTIES_ARM = 1000605001
M.VK_STRUCTURE_TYPE_PERFORMANCE_COUNTER_ARM = 1000605002
M.VK_STRUCTURE_TYPE_PERFORMANCE_COUNTER_DESCRIPTION_ARM = 1000605003
M.VK_STRUCTURE_TYPE_RENDER_PASS_PERFORMANCE_COUNTERS_BY_REGION_BEGIN_INFO_ARM = 1000605004
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_ROBUSTNESS_FEATURES_EXT = 1000608000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FORMAT_PACK_FEATURES_ARM = 1000609000
M.VK_FORMAT_R10X6_UINT_PACK16_ARM = 1000609000
M.VK_FORMAT_R10X6G10X6_UINT_2PACK16_ARM = 1000609001
M.VK_FORMAT_R10X6G10X6B10X6A10X6_UINT_4PACK16_ARM = 1000609002
M.VK_FORMAT_R12X4_UINT_PACK16_ARM = 1000609003
M.VK_FORMAT_R12X4G12X4_UINT_2PACK16_ARM = 1000609004
M.VK_FORMAT_R12X4G12X4B12X4A12X4_UINT_4PACK16_ARM = 1000609005
M.VK_FORMAT_R14X2_UINT_PACK16_ARM = 1000609006
M.VK_FORMAT_R14X2G14X2_UINT_2PACK16_ARM = 1000609007
M.VK_FORMAT_R14X2G14X2B14X2A14X2_UINT_4PACK16_ARM = 1000609008
M.VK_FORMAT_R14X2_UNORM_PACK16_ARM = 1000609009
M.VK_FORMAT_R14X2G14X2_UNORM_2PACK16_ARM = 1000609010
M.VK_FORMAT_R14X2G14X2B14X2A14X2_UNORM_4PACK16_ARM = 1000609011
M.VK_FORMAT_G14X2_B14X2R14X2_2PLANE_420_UNORM_3PACK16_ARM = 1000609012
M.VK_FORMAT_G14X2_B14X2R14X2_2PLANE_422_UNORM_3PACK16_ARM = 1000609013
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_LAYERED_FEATURES_VALVE = 1000611000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_LAYERED_PROPERTIES_VALVE = 1000611001
M.VK_STRUCTURE_TYPE_PIPELINE_FRAGMENT_DENSITY_MAP_LAYERED_CREATE_INFO_VALVE = 1000611002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ROBUSTNESS_2_FEATURES_KHR = 1000286000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ROBUSTNESS_2_PROPERTIES_KHR = 1000286001
M.VK_STRUCTURE_TYPE_SET_PRESENT_CONFIG_NV = 1000613000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENT_METERING_FEATURES_NV = 1000613001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_OFFSET_FEATURES_EXT = 1000425000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_OFFSET_PROPERTIES_EXT = 1000425001
M.VK_STRUCTURE_TYPE_RENDER_PASS_FRAGMENT_DENSITY_MAP_OFFSET_END_INFO_EXT = 1000425002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ZERO_INITIALIZE_DEVICE_MEMORY_FEATURES_EXT = 1000620000
M.VK_IMAGE_LAYOUT_ZERO_INITIALIZED_EXT = 1000620000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRESENT_MODE_FIFO_LATEST_READY_FEATURES_KHR = 1000361000
M.VK_PRESENT_MODE_FIFO_LATEST_READY_KHR = 1000361000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_64_BIT_INDEXING_FEATURES_EXT = 1000627000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CUSTOM_RESOLVE_FEATURES_EXT = 1000628000
M.VK_STRUCTURE_TYPE_BEGIN_CUSTOM_RESOLVE_INFO_EXT = 1000628001
M.VK_STRUCTURE_TYPE_CUSTOM_RESOLVE_CREATE_INFO_EXT = 1000628002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DATA_GRAPH_MODEL_FEATURES_QCOM = 1000629000
M.VK_STRUCTURE_TYPE_DATA_GRAPH_PIPELINE_BUILTIN_MODEL_CREATE_INFO_QCOM = 1000629001
M.VK_PHYSICAL_DEVICE_DATA_GRAPH_PROCESSING_ENGINE_TYPE_NEURAL_QCOM = 1000629000
M.VK_PHYSICAL_DEVICE_DATA_GRAPH_PROCESSING_ENGINE_TYPE_COMPUTE_QCOM = 1000629001
M.VK_PHYSICAL_DEVICE_DATA_GRAPH_OPERATION_TYPE_NEURAL_MODEL_QCOM = 1000629000
M.VK_PHYSICAL_DEVICE_DATA_GRAPH_OPERATION_TYPE_BUILTIN_MODEL_QCOM = 1000629001
M.VK_PIPELINE_CACHE_HEADER_VERSION_DATA_GRAPH_QCOM = 1000629000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_10_FEATURES_KHR = 1000630000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_10_PROPERTIES_KHR = 1000630001
M.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_FLAGS_INFO_KHR = 1000630002
M.VK_STRUCTURE_TYPE_RENDERING_END_INFO_KHR = 1000619003
M.VK_STRUCTURE_TYPE_RESOLVE_IMAGE_MODE_INFO_KHR = 1000630004
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_LONG_VECTOR_FEATURES_EXT = 1000635000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_LONG_VECTOR_PROPERTIES_EXT = 1000635001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_CACHE_INCREMENTAL_MODE_FEATURES_SEC = 1000637000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_UNIFORM_BUFFER_UNSIZED_ARRAY_FEATURES_EXT = 1000642000
M.VK_STRUCTURE_TYPE_COMPUTE_OCCUPANCY_PRIORITY_PARAMETERS_NV = 1000645000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COMPUTE_OCCUPANCY_PRIORITY_FEATURES_NV = 1000645001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SUBGROUP_PARTITIONED_FEATURES_EXT = 1000662000
M.VK_STRUCTURE_TYPE_UBM_SURFACE_CREATE_INFO_SEC = 1000664000
M.VK_ERROR_VALIDATION_FAILED = 1000011001
M.VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_INFO = 1000157000
M.VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_INFO = 1000157001
M.VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS = 1000127000
M.VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO = 1000127001
M.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO = 1000060000
M.VK_STRUCTURE_TYPE_DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO = 1000060004
M.VK_STRUCTURE_TYPE_DEVICE_GROUP_SUBMIT_INFO = 1000060005
M.VK_STRUCTURE_TYPE_DEVICE_GROUP_BIND_SPARSE_INFO = 1000060006
M.VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO = 1000060013
M.VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO = 1000060014
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GROUP_PROPERTIES = 1000070000
M.VK_STRUCTURE_TYPE_DEVICE_GROUP_DEVICE_CREATE_INFO = 1000070001
M.VK_STRUCTURE_TYPE_BUFFER_MEMORY_REQUIREMENTS_INFO_2 = 1000146000
M.VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2 = 1000146001
M.VK_STRUCTURE_TYPE_IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2 = 1000146002
M.VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2 = 1000146003
M.VK_STRUCTURE_TYPE_SPARSE_IMAGE_MEMORY_REQUIREMENTS_2 = 1000146004
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2 = 1000059000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2 = 1000059001
M.VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2 = 1000059002
M.VK_STRUCTURE_TYPE_IMAGE_FORMAT_PROPERTIES_2 = 1000059003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2 = 1000059004
M.VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2 = 1000059005
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2 = 1000059006
M.VK_STRUCTURE_TYPE_SPARSE_IMAGE_FORMAT_PROPERTIES_2 = 1000059007
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2 = 1000059008
M.VK_ERROR_OUT_OF_POOL_MEMORY = 1000069000
M.VK_STRUCTURE_TYPE_IMAGE_VIEW_USAGE_CREATE_INFO = 1000117002
M.VK_STRUCTURE_TYPE_PROTECTED_SUBMIT_INFO = 1000145000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_FEATURES = 1000145001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_PROPERTIES = 1000145002
M.VK_STRUCTURE_TYPE_DEVICE_QUEUE_INFO_2 = 1000145003
M.VK_FORMAT_G8B8G8R8_422_UNORM = 1000156000
M.VK_FORMAT_B8G8R8G8_422_UNORM = 1000156001
M.VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM = 1000156002
M.VK_FORMAT_G8_B8R8_2PLANE_420_UNORM = 1000156003
M.VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM = 1000156004
M.VK_FORMAT_G8_B8R8_2PLANE_422_UNORM = 1000156005
M.VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM = 1000156006
M.VK_FORMAT_R10X6_UNORM_PACK16 = 1000156007
M.VK_FORMAT_R10X6G10X6_UNORM_2PACK16 = 1000156008
M.VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16 = 1000156009
M.VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16 = 1000156010
M.VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16 = 1000156011
M.VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16 = 1000156012
M.VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16 = 1000156013
M.VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16 = 1000156014
M.VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16 = 1000156015
M.VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16 = 1000156016
M.VK_FORMAT_R12X4_UNORM_PACK16 = 1000156017
M.VK_FORMAT_R12X4G12X4_UNORM_2PACK16 = 1000156018
M.VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16 = 1000156019
M.VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16 = 1000156020
M.VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16 = 1000156021
M.VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16 = 1000156022
M.VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16 = 1000156023
M.VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16 = 1000156024
M.VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16 = 1000156025
M.VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16 = 1000156026
M.VK_FORMAT_G16B16G16R16_422_UNORM = 1000156027
M.VK_FORMAT_B16G16R16G16_422_UNORM = 1000156028
M.VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM = 1000156029
M.VK_FORMAT_G16_B16R16_2PLANE_420_UNORM = 1000156030
M.VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM = 1000156031
M.VK_FORMAT_G16_B16R16_2PLANE_422_UNORM = 1000156032
M.VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM = 1000156033
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO = 1000071000
M.VK_STRUCTURE_TYPE_EXTERNAL_IMAGE_FORMAT_PROPERTIES = 1000071001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO = 1000071002
M.VK_STRUCTURE_TYPE_EXTERNAL_BUFFER_PROPERTIES = 1000071003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES = 1000071004
M.VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO = 1000072000
M.VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO = 1000072001
M.VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO = 1000072002
M.VK_ERROR_INVALID_EXTERNAL_HANDLE = 1000072003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO = 1000112000
M.VK_STRUCTURE_TYPE_EXTERNAL_FENCE_PROPERTIES = 1000112001
M.VK_STRUCTURE_TYPE_EXPORT_FENCE_CREATE_INFO = 1000113000
M.VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_CREATE_INFO = 1000077000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO = 1000076000
M.VK_STRUCTURE_TYPE_EXTERNAL_SEMAPHORE_PROPERTIES = 1000076001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_PROPERTIES = 1000094000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES = 1000083000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES = 1000120000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES = 1000120000
M.VK_STRUCTURE_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO = 1000085000
M.VK_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE = 1000085000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES = 1000168000
M.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_SUPPORT = 1000168001
M.VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_CREATE_INFO = 1000156000
M.VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_INFO = 1000156001
M.VK_STRUCTURE_TYPE_BIND_IMAGE_PLANE_MEMORY_INFO = 1000156002
M.VK_STRUCTURE_TYPE_IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO = 1000156003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES = 1000156004
M.VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES = 1000156005
M.VK_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION = 1000156000
M.VK_STRUCTURE_TYPE_DEVICE_GROUP_RENDER_PASS_BEGIN_INFO = 1000060003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES = 1000117000
M.VK_STRUCTURE_TYPE_RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO = 1000117001
M.VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO = 1000117003
M.VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL = 1000117000
M.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL = 1000117001
M.VK_STRUCTURE_TYPE_RENDER_PASS_MULTIVIEW_CREATE_INFO = 1000053000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_FEATURES = 1000053001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES = 1000053002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETERS_FEATURES = 1000063000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETER_FEATURES = 1000063000
M.VK_STRUCTURE_TYPE_IMAGE_FORMAT_LIST_CREATE_INFO = 1000147000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DRIVER_PROPERTIES = 1000196000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_MEMORY_MODEL_FEATURES = 1000211000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_HOST_QUERY_RESET_FEATURES = 1000261000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES = 1000207000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_PROPERTIES = 1000207001
M.VK_STRUCTURE_TYPE_SEMAPHORE_TYPE_CREATE_INFO = 1000207002
M.VK_STRUCTURE_TYPE_TIMELINE_SEMAPHORE_SUBMIT_INFO = 1000207003
M.VK_STRUCTURE_TYPE_SEMAPHORE_WAIT_INFO = 1000207004
M.VK_STRUCTURE_TYPE_SEMAPHORE_SIGNAL_INFO = 1000207005
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES = 1000257000
M.VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO = 1000244001
M.VK_STRUCTURE_TYPE_BUFFER_OPAQUE_CAPTURE_ADDRESS_CREATE_INFO = 1000257002
M.VK_STRUCTURE_TYPE_MEMORY_OPAQUE_CAPTURE_ADDRESS_ALLOCATE_INFO = 1000257003
M.VK_STRUCTURE_TYPE_DEVICE_MEMORY_OPAQUE_CAPTURE_ADDRESS_INFO = 1000257004
M.VK_ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS = 1000257000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES = 1000177000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ATOMIC_INT64_FEATURES = 1000180000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_FLOAT16_INT8_FEATURES = 1000082000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FLOAT_CONTROLS_PROPERTIES = 1000197000
M.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO = 1000161000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES = 1000161001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_PROPERTIES = 1000161002
M.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_ALLOCATE_INFO = 1000161003
M.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_LAYOUT_SUPPORT = 1000161004
M.VK_ERROR_FRAGMENTATION = 1000161000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SCALAR_BLOCK_LAYOUT_FEATURES = 1000221000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_FILTER_MINMAX_PROPERTIES = 1000130000
M.VK_STRUCTURE_TYPE_SAMPLER_REDUCTION_MODE_CREATE_INFO = 1000130001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_UNIFORM_BUFFER_STANDARD_LAYOUT_FEATURES = 1000253000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SUBGROUP_EXTENDED_TYPES_FEATURES = 1000175000
M.VK_STRUCTURE_TYPE_ATTACHMENT_DESCRIPTION_2 = 1000109000
M.VK_STRUCTURE_TYPE_ATTACHMENT_REFERENCE_2 = 1000109001
M.VK_STRUCTURE_TYPE_SUBPASS_DESCRIPTION_2 = 1000109002
M.VK_STRUCTURE_TYPE_SUBPASS_DEPENDENCY_2 = 1000109003
M.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO_2 = 1000109004
M.VK_STRUCTURE_TYPE_SUBPASS_BEGIN_INFO = 1000109005
M.VK_STRUCTURE_TYPE_SUBPASS_END_INFO = 1000109006
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_STENCIL_RESOLVE_PROPERTIES = 1000199000
M.VK_STRUCTURE_TYPE_SUBPASS_DESCRIPTION_DEPTH_STENCIL_RESOLVE = 1000199001
M.VK_STRUCTURE_TYPE_IMAGE_STENCIL_USAGE_CREATE_INFO = 1000246000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGELESS_FRAMEBUFFER_FEATURES = 1000108000
M.VK_STRUCTURE_TYPE_FRAMEBUFFER_ATTACHMENTS_CREATE_INFO = 1000108001
M.VK_STRUCTURE_TYPE_FRAMEBUFFER_ATTACHMENT_IMAGE_INFO = 1000108002
M.VK_STRUCTURE_TYPE_RENDER_PASS_ATTACHMENT_BEGIN_INFO = 1000108003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SEPARATE_DEPTH_STENCIL_LAYOUTS_FEATURES = 1000241000
M.VK_STRUCTURE_TYPE_ATTACHMENT_REFERENCE_STENCIL_LAYOUT = 1000241001
M.VK_STRUCTURE_TYPE_ATTACHMENT_DESCRIPTION_STENCIL_LAYOUT = 1000241002
M.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL = 1000241000
M.VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_OPTIMAL = 1000241001
M.VK_IMAGE_LAYOUT_STENCIL_ATTACHMENT_OPTIMAL = 1000241002
M.VK_IMAGE_LAYOUT_STENCIL_READ_ONLY_OPTIMAL = 1000241003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TOOL_PROPERTIES = 1000245000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PRIVATE_DATA_FEATURES = 1000295000
M.VK_STRUCTURE_TYPE_DEVICE_PRIVATE_DATA_CREATE_INFO = 1000295001
M.VK_STRUCTURE_TYPE_PRIVATE_DATA_SLOT_CREATE_INFO = 1000295002
M.VK_OBJECT_TYPE_PRIVATE_DATA_SLOT = 1000295000
M.VK_STRUCTURE_TYPE_MEMORY_BARRIER_2 = 1000314000
M.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER_2 = 1000314001
M.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2 = 1000314002
M.VK_STRUCTURE_TYPE_DEPENDENCY_INFO = 1000314003
M.VK_STRUCTURE_TYPE_SUBMIT_INFO_2 = 1000314004
M.VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO = 1000314005
M.VK_STRUCTURE_TYPE_COMMAND_BUFFER_SUBMIT_INFO = 1000314006
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES = 1000314007
M.VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL = 1000314000
M.VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL = 1000314001
M.VK_STRUCTURE_TYPE_COPY_BUFFER_INFO_2 = 1000337000
M.VK_STRUCTURE_TYPE_COPY_IMAGE_INFO_2 = 1000337001
M.VK_STRUCTURE_TYPE_COPY_BUFFER_TO_IMAGE_INFO_2 = 1000337002
M.VK_STRUCTURE_TYPE_COPY_IMAGE_TO_BUFFER_INFO_2 = 1000337003
M.VK_STRUCTURE_TYPE_BUFFER_COPY_2 = 1000337006
M.VK_STRUCTURE_TYPE_IMAGE_COPY_2 = 1000337007
M.VK_STRUCTURE_TYPE_BUFFER_IMAGE_COPY_2 = 1000337009
M.VK_FORMAT_G8_B8R8_2PLANE_444_UNORM = 1000330000
M.VK_FORMAT_G10X6_B10X6R10X6_2PLANE_444_UNORM_3PACK16 = 1000330001
M.VK_FORMAT_G12X4_B12X4R12X4_2PLANE_444_UNORM_3PACK16 = 1000330002
M.VK_FORMAT_G16_B16R16_2PLANE_444_UNORM = 1000330003
M.VK_FORMAT_A4R4G4B4_UNORM_PACK16 = 1000340000
M.VK_FORMAT_A4B4G4R4_UNORM_PACK16 = 1000340001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TEXTURE_COMPRESSION_ASTC_HDR_FEATURES = 1000066000
M.VK_FORMAT_ASTC_4x4_SFLOAT_BLOCK = 1000066000
M.VK_FORMAT_ASTC_5x4_SFLOAT_BLOCK = 1000066001
M.VK_FORMAT_ASTC_5x5_SFLOAT_BLOCK = 1000066002
M.VK_FORMAT_ASTC_6x5_SFLOAT_BLOCK = 1000066003
M.VK_FORMAT_ASTC_6x6_SFLOAT_BLOCK = 1000066004
M.VK_FORMAT_ASTC_8x5_SFLOAT_BLOCK = 1000066005
M.VK_FORMAT_ASTC_8x6_SFLOAT_BLOCK = 1000066006
M.VK_FORMAT_ASTC_8x8_SFLOAT_BLOCK = 1000066007
M.VK_FORMAT_ASTC_10x5_SFLOAT_BLOCK = 1000066008
M.VK_FORMAT_ASTC_10x6_SFLOAT_BLOCK = 1000066009
M.VK_FORMAT_ASTC_10x8_SFLOAT_BLOCK = 1000066010
M.VK_FORMAT_ASTC_10x10_SFLOAT_BLOCK = 1000066011
M.VK_FORMAT_ASTC_12x10_SFLOAT_BLOCK = 1000066012
M.VK_FORMAT_ASTC_12x12_SFLOAT_BLOCK = 1000066013
M.VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_3 = 1000360000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_4_FEATURES = 1000413000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_4_PROPERTIES = 1000413001
M.VK_STRUCTURE_TYPE_DEVICE_BUFFER_MEMORY_REQUIREMENTS = 1000413002
M.VK_STRUCTURE_TYPE_DEVICE_IMAGE_MEMORY_REQUIREMENTS = 1000413003
M.VK_STRUCTURE_TYPE_PIPELINE_CREATION_FEEDBACK_CREATE_INFO = 1000192000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_TERMINATE_INVOCATION_FEATURES = 1000215000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DEMOTE_TO_HELPER_INVOCATION_FEATURES = 1000276000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_CREATION_CACHE_CONTROL_FEATURES = 1000297000
M.VK_PIPELINE_COMPILE_REQUIRED = 1000297000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ZERO_INITIALIZE_WORKGROUP_MEMORY_FEATURES = 1000325000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_ROBUSTNESS_FEATURES = 1000335000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_SIZE_CONTROL_PROPERTIES = 1000225000
M.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO = 1000225001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_SIZE_CONTROL_FEATURES = 1000225002
M.VK_DESCRIPTOR_TYPE_INLINE_UNIFORM_BLOCK = 1000138000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_FEATURES = 1000138000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_PROPERTIES = 1000138001
M.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_INLINE_UNIFORM_BLOCK = 1000138002
M.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_INLINE_UNIFORM_BLOCK_CREATE_INFO = 1000138003
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_INTEGER_DOT_PRODUCT_FEATURES = 1000280000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_INTEGER_DOT_PRODUCT_PROPERTIES = 1000280001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TEXEL_BUFFER_ALIGNMENT_PROPERTIES = 1000281001
M.VK_STRUCTURE_TYPE_BLIT_IMAGE_INFO_2 = 1000337004
M.VK_STRUCTURE_TYPE_RESOLVE_IMAGE_INFO_2 = 1000337005
M.VK_STRUCTURE_TYPE_IMAGE_BLIT_2 = 1000337008
M.VK_STRUCTURE_TYPE_IMAGE_RESOLVE_2 = 1000337010
M.VK_STRUCTURE_TYPE_RENDERING_INFO = 1000044000
M.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO = 1000044001
M.VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO = 1000044002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES = 1000044003
M.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_RENDERING_INFO = 1000044004
M.VK_ATTACHMENT_STORE_OP_NONE = 1000301000
M.VK_DYNAMIC_STATE_CULL_MODE = 1000267000
M.VK_DYNAMIC_STATE_FRONT_FACE = 1000267001
M.VK_DYNAMIC_STATE_PRIMITIVE_TOPOLOGY = 1000267002
M.VK_DYNAMIC_STATE_VIEWPORT_WITH_COUNT = 1000267003
M.VK_DYNAMIC_STATE_SCISSOR_WITH_COUNT = 1000267004
M.VK_DYNAMIC_STATE_VERTEX_INPUT_BINDING_STRIDE = 1000267005
M.VK_DYNAMIC_STATE_DEPTH_TEST_ENABLE = 1000267006
M.VK_DYNAMIC_STATE_DEPTH_WRITE_ENABLE = 1000267007
M.VK_DYNAMIC_STATE_DEPTH_COMPARE_OP = 1000267008
M.VK_DYNAMIC_STATE_DEPTH_BOUNDS_TEST_ENABLE = 1000267009
M.VK_DYNAMIC_STATE_STENCIL_TEST_ENABLE = 1000267010
M.VK_DYNAMIC_STATE_STENCIL_OP = 1000267011
M.VK_DYNAMIC_STATE_RASTERIZER_DISCARD_ENABLE = 1000377001
M.VK_DYNAMIC_STATE_DEPTH_BIAS_ENABLE = 1000377002
M.VK_DYNAMIC_STATE_PRIMITIVE_RESTART_ENABLE = 1000377004
M.VK_STRUCTURE_TYPE_DEVICE_QUEUE_GLOBAL_PRIORITY_CREATE_INFO = 1000174000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GLOBAL_PRIORITY_QUERY_FEATURES = 1000388000
M.VK_STRUCTURE_TYPE_QUEUE_FAMILY_GLOBAL_PRIORITY_PROPERTIES = 1000388001
M.VK_ERROR_NOT_PERMITTED = 1000174001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INDEX_TYPE_UINT8_FEATURES = 1000265000
M.VK_INDEX_TYPE_UINT8 = 1000265000
M.VK_STRUCTURE_TYPE_MEMORY_MAP_INFO = 1000271000
M.VK_STRUCTURE_TYPE_MEMORY_UNMAP_INFO = 1000271001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_5_FEATURES = 1000470000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_5_PROPERTIES = 1000470001
M.VK_STRUCTURE_TYPE_DEVICE_IMAGE_SUBRESOURCE_INFO = 1000470004
M.VK_FORMAT_A1B5G5R5_UNORM_PACK16 = 1000470000
M.VK_FORMAT_A8_UNORM = 1000470001
M.VK_STRUCTURE_TYPE_SUBRESOURCE_LAYOUT_2 = 1000338002
M.VK_STRUCTURE_TYPE_IMAGE_SUBRESOURCE_2 = 1000338003
M.VK_STRUCTURE_TYPE_BUFFER_USAGE_FLAGS_2_CREATE_INFO = 1000470006
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_6_FEATURES = 1000545000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_6_PROPERTIES = 1000545001
M.VK_STRUCTURE_TYPE_BIND_MEMORY_STATUS = 1000545002
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_HOST_IMAGE_COPY_FEATURES = 1000270000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_HOST_IMAGE_COPY_PROPERTIES = 1000270001
M.VK_STRUCTURE_TYPE_MEMORY_TO_IMAGE_COPY = 1000270002
M.VK_STRUCTURE_TYPE_IMAGE_TO_MEMORY_COPY = 1000270003
M.VK_STRUCTURE_TYPE_COPY_IMAGE_TO_MEMORY_INFO = 1000270004
M.VK_STRUCTURE_TYPE_COPY_MEMORY_TO_IMAGE_INFO = 1000270005
M.VK_STRUCTURE_TYPE_HOST_IMAGE_LAYOUT_TRANSITION_INFO = 1000270006
M.VK_STRUCTURE_TYPE_COPY_IMAGE_TO_IMAGE_INFO = 1000270007
M.VK_STRUCTURE_TYPE_SUBRESOURCE_HOST_MEMCPY_SIZE = 1000270008
M.VK_STRUCTURE_TYPE_HOST_IMAGE_COPY_DEVICE_PERFORMANCE_QUERY = 1000270009
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SUBGROUP_ROTATE_FEATURES = 1000416000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_FLOAT_CONTROLS_2_FEATURES = 1000528000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_EXPECT_ASSUME_FEATURES = 1000544000
M.VK_STRUCTURE_TYPE_PIPELINE_CREATE_FLAGS_2_CREATE_INFO = 1000470005
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PUSH_DESCRIPTOR_PROPERTIES = 1000080000
M.VK_STRUCTURE_TYPE_BIND_DESCRIPTOR_SETS_INFO = 1000545003
M.VK_STRUCTURE_TYPE_PUSH_CONSTANTS_INFO = 1000545004
M.VK_STRUCTURE_TYPE_PUSH_DESCRIPTOR_SET_INFO = 1000545005
M.VK_STRUCTURE_TYPE_PUSH_DESCRIPTOR_SET_WITH_TEMPLATE_INFO = 1000545006
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_PROTECTED_ACCESS_FEATURES = 1000466000
M.VK_STRUCTURE_TYPE_PIPELINE_ROBUSTNESS_CREATE_INFO = 1000068000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_ROBUSTNESS_FEATURES = 1000068001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_ROBUSTNESS_PROPERTIES = 1000068002
M.VK_ATTACHMENT_LOAD_OP_NONE = 1000400000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_LINE_RASTERIZATION_FEATURES = 1000259000
M.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_LINE_STATE_CREATE_INFO = 1000259001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_LINE_RASTERIZATION_PROPERTIES = 1000259002
M.VK_DYNAMIC_STATE_LINE_STIPPLE = 1000259000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_PROPERTIES = 1000525000
M.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_DIVISOR_STATE_CREATE_INFO = 1000190001
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_FEATURES = 1000190002
M.VK_STRUCTURE_TYPE_RENDERING_AREA_INFO = 1000470003
M.VK_IMAGE_LAYOUT_RENDERING_LOCAL_READ = 1000232000
M.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_LOCAL_READ_FEATURES = 1000232000
M.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_LOCATION_INFO = 1000232001
M.VK_STRUCTURE_TYPE_RENDERING_INPUT_ATTACHMENT_INDEX_INFO = 1000232002
setmetatable(M, { __index = function(t, k)
    local ok, res = pcall(function() return ffi_lib[k] end)
    if ok then return res end
    return ffi.C[k]
end })

M.VK_API_VERSION_1_3 = 4202496
return M
