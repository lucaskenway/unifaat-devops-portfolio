// src/feature-flags.js
// Sistema de Feature Flags da TechNova API
//
// As flags vêm de variáveis de ambiente com prefixo FF_ (FF_NEW_SHIPPING_CALC=true vira
// a flag "new_shipping_calc"). Desligar uma feature é só trocar a variável e reiniciar o
// container: nenhuma imagem nova é construída, nenhum pipeline roda. É o "rollback"
// mais rápido que existe para um problema isolado numa feature.

const PREFIX = 'FF_';

// Valores padrão: valem quando a variável não foi definida no ambiente.
// Feature nova nasce desligada; só o novo frete está ligado por padrão.
const DEFAULTS = {
  new_shipping_calc: true,
  bulk_orders: false,
  ai_recommendations: false,
  new_checkout: false
};

function parseBool(value) {
  return ['true', '1', 'on', 'yes'].includes(String(value).trim().toLowerCase());
}

class FeatureFlags {
  constructor(env = process.env) {
    this.env = env;
    this.flags = {};
    this.loadFlags();
  }

  loadFlags() {
    const flags = { ...DEFAULTS };
    Object.keys(this.env)
      .filter(key => key.startsWith(PREFIX))
      .forEach(key => {
        const flagName = key.slice(PREFIX.length).toLowerCase();
        flags[flagName] = parseBool(this.env[key]);
      });
    this.flags = flags;
    this.loadedAt = new Date().toISOString();

    if (this.env.NODE_ENV !== 'test') {
      console.log('[FeatureFlags] Flags carregadas:', JSON.stringify(this.flags));
    }
    return this.flags;
  }

  isEnabled(flagName) {
    return this.flags[String(flagName).toLowerCase()] === true;
  }

  getAllFlags() {
    return { ...this.flags };
  }

  // Relê o ambiente (útil em testes e numa integração futura com AppConfig)
  reload() {
    return this.loadFlags();
  }
}

// Singleton usado pela aplicação; a classe é exportada para os testes
const featureFlags = new FeatureFlags();
module.exports = featureFlags;
module.exports.FeatureFlags = FeatureFlags;
module.exports.DEFAULTS = DEFAULTS;
