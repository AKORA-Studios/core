import{_ as p,q as r,k as s,l as m,B as o,M as c,x as _}from"./vendor-033b944b.js";import"./vendor-sortablejs-01d816ac.js";const f={name:"RippleControlReceiverDimmKit",emits:["update:configuration"],props:{rippleControlReceiver:{type:Object,required:!0}},data(){return{}},methods:{updateConfiguration(a,e=void 0){this.$emit("update:configuration",{value:a,object:e})}}},b={class:"ripple-control-receiver-dimm-kit"};function v(a,e,n,g,C,i){const d=r("openwb-base-alert"),u=r("openwb-base-text-input"),l=r("openwb-base-number-input");return s(),m("div",b,[o(d,{subtype:"info"},{default:c(()=>[_(" Wenn mindestens ein Kontakt offen ist, wird die Ladung gesperrt. Wenn beide Kontakte geschlossen sind, darf geladen werden. ")]),_:1}),o(u,{title:"IP oder Hostname",subtype:"host",required:"","model-value":n.rippleControlReceiver.configuration.ip_address,"onUpdate:modelValue":e[0]||(e[0]=t=>i.updateConfiguration(t,"configuration.ip_address"))},null,8,["model-value"]),o(l,{title:"Port",required:"","model-value":n.rippleControlReceiver.configuration.port,"onUpdate:modelValue":e[1]||(e[1]=t=>i.updateConfiguration(t,"configuration.port"))},null,8,["model-value"]),o(l,{title:"Modbus-ID",required:"",min:1,max:255,"model-value":n.rippleControlReceiver.configuration.modbus_id,"onUpdate:modelValue":e[2]||(e[2]=t=>i.updateConfiguration(t,"configuration.modbus_id"))},null,8,["model-value"])])}const k=p(f,[["render",v],["__file","/opt/openWB-dev/openwb-ui-settings/src/components/ripple_control_receivers/dimm_kit/ripple_control_receiver.vue"]]);export{k as default};
