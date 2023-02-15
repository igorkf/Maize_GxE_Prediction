import lightgbm as lgbm
import optuna

from evaluate import create_df_eval, avg_rmse


def objective(trial, xtrain, ytrain, xval, yval):
    """
    https://medium.com/optuna/lightgbm-tuner-new-optuna-integration-for-hyperparameter-optimization-8b7095e99258
    """
    params = {
        # 'bagging_freq': trial.suggest_int('bagging_freq', 1, 7),
        # 'min_child_samples': trial.suggest_int('min_child_samples', 5, 100),
        'feature_fraction': trial.suggest_float('feature_fraction', 0.0, 1.0),
        'num_leaves': trial.suggest_int('num_leaves', 2, 256),
        'bagging_fraction': trial.suggest_float('bagging_fraction', 0.4, 1.0),
        'lambda_l1': trial.suggest_float('lambda_l1', 1e-8, 10.0, log=True),
        'lambda_l2': trial.suggest_float('lambda_l2', 1e-8, 10.0, log=True),
        # 'min_samples_leaf': trial.suggest_int('min_samples_leaf', 1, 10),
        'n_estimators': trial.suggest_int('n_estimators', 10, 300),
        'max_depth': trial.suggest_int('max_depth', 2, 6),
        'deterministic': True,
        'random_state': 42
    }
    
    # fit
    model = lgbm.LGBMRegressor(**params)
    model.fit(xtrain, ytrain)

    # predict
    ypred = model.predict(xval)

    # validate
    df_eval = create_df_eval(xval, yval, ypred)
    return avg_rmse(df_eval, verbose=False)
